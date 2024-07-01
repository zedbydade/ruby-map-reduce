require 'grpc'
require 'logger'
require_relative 'master'

def start_master(_files, reduce_count, worker_timeout, worker_count, logger, map_count)
  master = Master.new(reduce_count:, worker_timeout:, logger:, map_count:, worker_count:)
  grpc_server = GRPC::RpcServer.new
  grpc_server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
  grpc_server.handle(master)
  Thread.new do
    logger.info('[Master] Master gRPC server start')
    grpc_server.run_till_terminated
  end
  master.wait_for_enough_workers
  master.distribute_work
  master
end

logger = Logger.new($stdout)
master = start_master(nil, 5, 40, 10, logger, 5)
logger.info(master.data)

loop do
  sleep 1
end
