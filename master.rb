require 'grpc'
require 'digest'
require_relative './lib/server_services_pb'

class Master < MapReduceMaster::Service
  @data = {}
  attr_accessor :worker_timeout

  class << self
    attr_accessor :data
  end

  def initialize(worker_timeout: 10, worker_count: 2)
    @worker_timeout = worker_timeout
    @worker_count = worker_count
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

  def split_files(key, file)
    encrypt_key = generate_digest_key(key)
    FileUtils.mkdir_p("./files/#{encrypt_key}")
    line_maximum = (File.open(file).count / @worker_count).to_i
    file_data = file.readlines.map(&:chomp)
    file_number = file_data.length / line_maximum
    file_number.times do |index|
      File.write("./files/#{encrypt_key}/file_#{index}", file_data.slice!(0..line_maximum))
    end
  end

  def generate_digest_key(key)
    digest = Digest::SHA256.new
    digest.update(key)
    digest.hexdigest
  end
end
