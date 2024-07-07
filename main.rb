require 'grpc'
require 'logger'
require 'map_reduce'

def start_master(file, logger, map_count)
  master = MapReduce.new(logger:, map_count:, file:)
  grpc_server = GRPC::RpcServer.new
  grpc_server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
  grpc_server.handle(master)
  Thread.new do
    logger.info('[Master] Master gRPC server start')
    grpc_server.run_till_terminated
  end
  master.wait_for_enough_workers
  master.distribute_input
  master.map do
    proc do |input|
      input = input.gsub(/[^\w\s]/, '')
      words = input.split(/\s+/)
      words.each do |l|
        emit_intermediate(l, count: 1)
      end
    end
  end
  master.reduce do
    proc do |input|
      result = input.each_with_object(Hash.new(0)) do |(flag, number), acc|
        acc[flag] += number
      end
      emit(result.to_a[0], count: result.to_a[1])
    end
  end
  master
end

logger = Logger.new($stdout)
master = start_master(Pathname.new('./test/file.txt'), logger, 5)
logger.info(master.data)

loop do
  sleep 1
end
