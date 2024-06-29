require 'grpc'
require 'async'
require_relative 'reduce_worker'
require_relative 'worker'
require 'digest'
require_relative './lib/server_services_pb'

class Master < MapReduceMaster::Service
  @data = {}
  attr_accessor :worker_timeout, :logger
  attr_reader :reduce_workers

  class << self
    attr_accessor :data
  end

  def initialize(logger:, worker_timeout: 10, worker_count: 2, reduce_count: 1)
    @worker_timeout = worker_timeout
    @worker_count = worker_count
    @reduce_workers = create_reduce_workers(reduce_count)
    @logger = logger
  end

  def create_map(maps_req, _)
    self.class.data[maps_req.id] = maps_req.message

    WorkerRequestCreateMap.new(message: "Succesful create message #{maps_req.message} with id #{maps_req.id}")
  end

  def get_maps(maps_req, _)
    WorkerResponseGetMap.new(message: self.class.data[maps_req.id])
  ensure
    self.class.data.delete(maps_req.id)
  end

  def wait_for_enough_workers
    logger.info('[Master] Wait for the creation of workers')
    workers = []
    Async do
      1.upto(@worker_count) do
        Async do
          workers << Worker.start_worker(logger)
        end
      end
    end
    p workers
    logger.info('[Master] Finished!')
  end

  def start_worker(_reduce_number)
    input = split_files
  end

  private

  def create_reduce_workers(reduce_count)
    reduce_workers = []
    reduce_count.times { reduce_workers << ReduceWorker.new }
  end

  def split_files(key, file)
    encrypt_key = generate_digest_key(key)
    FileUtils.mkdir_p("./files/#{encrypt_key}")
    line_maximum = (File.open(file).count / @worker_count).to_i
    file_data = file.readlines.map(&:chomp)
    file_number = file_data.length / line_maximum
    files = []
    file_number.times do |index|
      files << File.write("./files/#{encrypt_key}/file_#{index}", file_data.slice!(0..line_maximum))
    end
  end

  def generate_digest_key(key)
    digest = Digest::SHA256.new
    digest.update(key)
    digest.hexdigest
  end
end
