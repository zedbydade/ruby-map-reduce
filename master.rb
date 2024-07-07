require 'grpc'
require 'async'
require 'async/semaphore'
require 'pathname'
require_relative 'reduce_worker'
require_relative 'worker'
require 'digest'
require 'method_source'
require_relative './lib/server_services_pb'
require_relative './lib/worker_services_pb'

class Master < MapReduceMaster::Service
  attr_accessor :logger, :worker_count, :map_count, :data, :files, :map_finished

  def initialize(logger:, map_count: 5, file:)
    @file = file
    @map_count = map_count
    @worker_count = 0
    @logger = logger
    @data = []
    @files = nil
    @map_finished = false
  end

  def ping(worker_req, _)
    uuid = worker_req.uuid
    success = worker_req.success
    worker = data.find { |w| w[:uuid] == uuid }
    worker[:status] = 0

    if success == 'true'
      logger.info("[Master] Worker #{uuid} completed the map operation succesful")
    else
      logger.info("[Master] Worker #{uuid} failed to complete the map opeartion successful")
      @files << worker_req.filename
    end

    Empty.new
  end

  def register_worker(worker_req, _)
    uuid = worker_req.uuid
    type = worker_req.type
    ip = worker_req.ip
    mutex = Mutex.new
    mutex.lock
    data << ({ uuid:, ip:, status: 0 })
    # That count is being back by the ruby GIL
    @worker_count += 1
    @logger.info('[Master] Worker register success')
    RegisterWorkerResult.new(result: true)
  ensure
    mutex.unlock
  end

  def wait_for_enough_workers
    logger.info('[Master] Wait for the creation of workers')
    Worker.start_worker(logger, map_count)
    logger.info('[Master] Finished!')
  end

  def reduce(&block)
    Thread.new do
      loop do
        next unless @map_finished == true

        block = block.source.sub(/^\s*master\.reduce do\s*\n/, '').sub(/^\s*end\s*\n/, '')
        message = Base64.encode64(block)
        worker = data.select { |w| w[:status] == 0 }.first

        stub = WorkerServer::Stub.new(worker[:ip], :this_channel_is_insecure)
        request = ReduceInfo.new(filename: "files/#{@encrypt_key}/map.txt", block: message, key: @encrypt_key)
        worker[:status] = 'processing'
        stub.reduce_operation(request)

        break
      end
    end
  end

  def map(&block)
    block = block.source.sub(/^\s*master\.map do\s*\n/, '').sub(/^\s*end\s*\n/, '')
    message = Base64.encode64(block)
    Thread.new do
      loop do
        @map_finished = true if files.empty?
        break if files.empty?

        Async do
          workers = data.select { |w| w[:status] == 0 }.first(files.count)

          semaphore = Async::Semaphore.new(workers.count)
          tasks = []

          workers.each do |worker|
            tasks << semaphore.async do
              stub = WorkerServer::Stub.new(worker[:ip], :this_channel_is_insecure)
              request = MapInfo.new(filename: files.pop, block: message, key: @encrypt_key)
              worker[:status] = 'processing'
              stub.map_operation(request)
            end
          end
          tasks.each(&:wait)
        end.wait
      end
    end
  end

  def distribute_input
    path_name = @file
    key = path_name.to_path
    logger.info('[Master] Start to distribute input')
    @files = split_files(key, path_name)
  end

  private

  def split_files(key, file)
    @encrypt_key = generate_digest_key(key)
    FileUtils.mkdir_p("./files/#{@encrypt_key}")
    line_maximum = (File.open(file).count / @map_count).to_i
    file_data = file.readlines.map(&:chomp)
    file_number = file_data.length / line_maximum
    files = []
    file_number.times do |index|
      path = "./files/#{@encrypt_key}/file_#{index}"
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
