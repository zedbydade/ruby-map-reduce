require './lib/worker_services_pb'
require 'base64'
require 'google/protobuf'
require './lib/server_services_pb'
require './lib/server_pb'
require 'async'
require 'logger'

class Worker < WorkerServer::Service
  attr_accessor :worker_number, :master_ip, :port, :logger, :uuid, :result

  def initialize(worker_number:, master_ip:, port:, logger:)
    @worker_number = worker_number
    @uuid = generate_uuid
    @master_ip = master_ip
    @port = port
    @logger = logger
    @result = []
  end

  def map_operation(worker_req, _)
    block = eval(Base64.decode64(worker_req.block))
    block.call(File.read(worker_req.filename))
    File.open('./example.txt', 'a') do |file|
      result.each do |array|
        file.puts array.inspect
      end
    end
    MapInfoResult.new(uuid:, result: true)
  end

  def start
    grpc_server = GRPC::RpcServer.new
    grpc_server.add_http2_port("0.0.0.0:#{port}", :this_port_is_insecure)
    grpc_server.handle(self)
    Thread.new do
      grpc_server.run_till_terminated
    ensure
      logger.info('[Worker] Worker gRPC thread failed')
    end
    logger.info('[Worker] Worker gRPC thread start')

    logger.info('[Worker] load functions finish')
    register_worker
  end

  def self.start_worker(logger, worker_number)
    master_ip = '0.0.0.0:50051'
    Async do
      1.upto(worker_number) do |i|
        Async do
          worker = new(worker_number:, master_ip:, port: "3000#{i}", logger:)
          worker.start
        end
      end
    end
  end

  private

  def emit(k, count:)
    result << [k, count]
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def register_worker
    stub = MapReduceMaster::Stub.new(@master_ip, :this_channel_is_insecure)
    request = RegisterWorkerRequest.new(uuid: @uuid, ip: "localhost:#{@port}")
    stub.register_worker(request)
    @logger.info('[Worker] Worker register itself finish')
  end
end
