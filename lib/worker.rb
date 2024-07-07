require_relative './grpc/worker_services_pb'
require_relative './grpc/server_services_pb'
require_relative './grpc/server_pb'
require 'base64'
require 'google/protobuf'
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
    File.open("files/#{worker_req.key}/map.txt", 'a') do |file|
      result.each do |array|
        file.puts array.inspect
      end
    end
    logger.info("[Worker] Worker #{uuid} gRPC finished the map operation")
    stub = MapReduceMaster::Stub.new(@master_ip, :this_channel_is_insecure)
    request = WorkerInfo.new(uuid: @uuid, success: 'true', filename: worker_req.filename)
    stub.ping(request)
    Empty.new
  rescue StandardError => e
    logger.error("[Worker] #{uuid} with error #{e}")
    stub = MapReduceMaster::Stub.new(@master_ip, :this_channel_is_insecure)
    request = WorkerInfo.new(uuid: @uuid, success: nil, filename: worker_req.filename)
    stub.ping(request)
  end

  def reduce_operation(worker_req, _)
    data = sort_map_file(worker_req.filename)
    unique_keys = data.map { |item| item[0] }.uniq
    file_path = "files/#{worker_req.key}/reduce.txt"
    logger.info('[Worker] Starting Reduce Operation')
    Async do
      1.upto(unique_keys.count) do |i|
        Async do
          results = data.select { |item| item[0] == unique_keys[i] }
          block = eval(Base64.decode64(worker_req.block))
          response = block.call(results)
          File.open(file_path, 'a') do |file|
            file.puts response
          end
        end
      end
    end
    logger.info('[Worker] Finished Reduce Operation')
    logger.info("[Worker] File stored at #{file_path}")
    Empty.new
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

  def sort_map_file(file_path)
    file_data = []
    File.open(file_path, 'r') do |file|
      file.each_line do |line|
        file_data << eval(line.strip)
      end
    end
    file_data.sort_by { |item| item[0] }
  end

  def emit_intermediate(k, count:)
    result << [k, count]
  end

  alias emit emit_intermediate

  def generate_uuid
    SecureRandom.uuid
  end

  def register_worker
    stub = MapReduceMaster::Stub.new(@master_ip, :this_channel_is_insecure)
    request = RegisterWorkerRequest.new(uuid: @uuid, ip: "localhost:#{@port}", type: 'map')
    stub.register_worker(request)
    @logger.info('[Worker] Worker register itself finish')
  end
end
