require 'grpc'
require 'async'
require 'pathname'
require_relative 'reduce_worker'
require_relative 'worker'
require 'digest'
require_relative './lib/server_services_pb'
require_relative './lib/worker_services_pb'

class Master < MapReduceMaster::Service
  attr_accessor :worker_timeout, :logger, :worker_count, :data
  attr_reader :reduce_workers

  def initialize(logger:, worker_timeout: 10, reduce_count: 5, map_count: 5, worker_count: 0)
    @worker_timeout = worker_timeout
    @worker_count = worker_count
    @map_count = map_count
    @logger = logger
    @data = {}
  end

  def register_worker(worker_req, _)
    uuid = worker_req.uuid
    ip = worker_req.ip
    mutex = Mutex.new
    mutex.lock
    data[uuid] = { uuid:, ip:, status: 'idle', type: nil }
    # That count is being back by the ruby GIL
    @worker_count += 1
    @logger.info('[Master] Worker register success')
    RegisterWorkerResult.new(result: true)
  ensure
    mutex.unlock
  end

  def wait_for_enough_workers
    logger.info('[Master] Wait for the creation of workers')
    Worker.start_worker(logger, worker_count)
    logger.info('[Master] Finished!')
  end

  def distribute_work
    path_name = Pathname.new('./test/joyboy.txt')
    key = path_name.to_path
    logger.info('[Master] Start to distribute work')
    files = split_files(key, path_name)
    data.each do |uuid|
      break if files.empty?

      stub = MapReduceMaster::Stub.new(uuid[:ip], :this_channel_is_insecure)
      request = MapOperation.new(uuid: @uuid, ip: "localhost:#{@port}")
      stub.map_operation(filename: files.pop, block:)
    end
  end

  private

  def split_files(key, file)
    encrypt_key = generate_digest_key(key)
    FileUtils.mkdir_p("./files/#{encrypt_key}")
    line_maximum = (File.open(file).count / @map_count).to_i
    file_data = file.readlines.map(&:chomp)
    file_number = file_data.length / line_maximum
    files = []
    file_number.times do |index|
      path = "./files/#{encrypt_key}/file_#{index}"
      File.write(path, file_data.slice!(0..line_maximum))
      files << path
    end
    files
  end

  def generate_digest_key(key)
    digest = Digest::SHA256.new
    digest.update(key)
    digest.hexdigest
  end
end
