require 'grpc'
require 'async'
require 'pathname'
require_relative 'reduce_worker'
require_relative 'worker'
require 'digest'
require 'method_source'
require_relative './lib/server_services_pb'
require_relative './lib/worker_services_pb'

class Master < MapReduceMaster::Service
  attr_accessor :worker_timeout, :logger, :worker_count, :data, :files
  attr_reader :reduce_workers

  def initialize(logger:, worker_timeout: 10, reduce_count: 5, map_count: 5, worker_count: 0)
    @worker_timeout = worker_timeout
    @worker_count = worker_count
    @map_count = map_count
    @logger = logger
    @data = []
    @files = nil
  end

  def register_worker(worker_req, _)
    uuid = worker_req.uuid
    ip = worker_req.ip
    mutex = Mutex.new
    mutex.lock
    data << { uuid:, ip:, status: 'idle', type: worker_req.type }
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

  def map(&block)
    block = block.source.sub(/^\s*master\.map do\s*\n/, '').sub(/^\s*end\s*\n/, '')
    message = Base64.encode64(block)
    Thread.new do
      loop do
        data.each do |worker|
          break if files.empty?

          stub = WorkerServer::Stub.new(worker[:ip], :this_channel_is_insecure)
          request = MapInfo.new(filename: files.pop, block: message)
          stub.map_operation(request)
        end
      end
    end
  end

  def distribute_input
    path_name = Pathname.new('./test/joyboy.txt')
    key = path_name.to_path
    logger.info('[Master] Start to distribute input')
    @files = split_files(key, path_name)
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
