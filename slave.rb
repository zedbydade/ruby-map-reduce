require_relative './lib/server_services_pb'
require_relative './lib/server_pb'

def slave
  loop do
    sleep(2)
    id = rand(1000)

    stub = MapReduceMaster::Stub.new('localhost:50051', :this_channel_is_insecure)

    request = WorkerRequestCreateMap.new(id:, message: '[1, 2, 3, 4].sum')

    stub.create_map(request)

    response = stub.get_maps(WorkerRequestGetMap.new(id:))

    p eval(response.message)
  end
end

slave
