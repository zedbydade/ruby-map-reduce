require './lib/worker_services_pb'
require 'google/protobuf'
require './lib/server_services_pb'
require './lib/server_pb'
require 'async'
require 'logger'

class Worker < WorkerServer::Service
  attr_accessor :reduce_number, :master_ip, :port, :logger, :uuid

  def initialize(reduce_number:, master_ip:, port:, logger:)
    @reducer_number = reduce_number
    @uuid = generate_uuid
    @master_ip = master_ip
    @port = port
    @logger = logger
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

    map_function = -> { [1, 2, 3, 4].map { |element| element * 2 } }
    reduce_function = -> { [1, 4, 6, 8].reduce(0) { |sum, element| sum + (element * 2) } }
    logger.info('[Worker] load functions finish')
    register_worker
  end

  def self.start_worker(logger)
    reduce_number = 1
    master_ip = '0.0.0.0:50051'
    Async do
      1.upto(10) do |i|
        Async do
          worker = new(reduce_number:, master_ip:, port: "3000#{i}", logger:)
          worker.start
        end
      end
    end
  end

  private

  def generate_uuid
    SecureRandom.uuid
  end

  def register_worker
    stub = MapReduceMaster::Stub.new(@master_ip, :this_channel_is_insecure)
    request = RegisterWorkerRequest.new(uuid: @uuid, ip: "localhost:#{@port}")
    stub.register_worker(request)
  end
end
