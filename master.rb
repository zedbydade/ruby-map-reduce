require 'grpc'
require 'async'
require_relative 'reduce_worker'
require_relative 'worker'
require 'digest'
require_relative './lib/server_services_pb'

class Master < MapReduceMaster::Service
  attr_accessor :worker_timeout, :logger, :worker_count, :data
  attr_reader :reduce_workers

  def initialize(logger:, worker_timeout: 10, reduce_count: 1)
    @worker_timeout = worker_timeout
    @worker_count = 0
    @reduce_workers = create_reduce_workers(reduce_count)
    @logger = logger
    @data = {}
  end

  def register_worker(worker_req, _)
    uuid = worker_req.uuid
    ip = worker_req.ip
    mutex = Mutex.new
    mutex.lock
    data[uuid] = { uuid:, ip: }
    @worker_count += 1
    @logger.info('[Master] Worker register success')
    RegisterWorkerResult.new(result: true)
  ensure
    mutex.unlock
  end

  def wait_for_enough_workers
    logger.info('[Master] Wait for the creation of workers')
    Worker.start_worker(logger)
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
