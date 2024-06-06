require 'grpc'
require_relative './lib/server_services_pb'

class Master < MapReduceMaster::Service
  @data = {}
  attr_accessor :worker_timeout

  class << self
    attr_accessor :data
  end

  def initialize(worker_timeout: 10)
    @worker_timeout = worker_timeout
    @data = {}
  end

  def create_map(maps_req, _)
    self.class.data[maps_req.id] = maps_req.message
    p self.class.data

    WorkerRequestCreateMap.new(message: "Succesful create message #{maps_req.message} with id #{maps_req.id}")
  end

  def get_maps(maps_req, _)
    p self.class.data
    WorkerResponseGetMap.new(message: self.class.data[maps_req.id])
  ensure
    self.class.data.delete(maps_req.id)
  end
end

def master
  server = GRPC::RpcServer.new
  server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
  server.handle(Master)
  p 'Running server'
  server.run_till_terminated
end

master
