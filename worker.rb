require_relative './lib/worker_services_pb'
require 'async'
require 'logger'

class Worker < WorkerServer::Service
  attr_accessor :reduce_number, :master_ip, :port, :logger

  def initialize(reduce_number:, master_ip:, port:, logger:)
    @reducer_number = reduce_number
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
  end

  def self.start_worker(logger)
    reduce_number = 1
    master_ip = '0.0.0.0:50051'
    workers = []
    Async do
      1.upto(10) do |i|
        Async do
          worker = new(reduce_number:, master_ip:, port: "3000#{i}", logger:)
          workers << worker.start
        end
      end
    end
    workers
  end
end
