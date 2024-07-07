# MapReduce Framework in Pure Ruby

This framework is designed to provide afully multi-threaded and asynchronous approach to MapReduce processing. Below, you will find a comprehensive guide on how to get started with this framework, including installation, usage, and examples.

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [License](#license)

## Introduction

This framework leverages the power of Ruby's threading and gRPC to provide a highly scalable and efficient MapReduce implementation. It is designed to handle large datasets by distributing the workload across multiple worker nodes, each capable of performing map and reduce tasks concurrently.

## Features

- **Pure Ruby Implementation**: No external dependencies required other than gRPC.
- **Multi-threaded and Asynchronous**: Efficiently manages multiple workers and tasks concurrently.
- **Customizable Map and Reduce Functions**: Define your own map and reduce logic to process data.
- **Logging**: Built-in logging to monitor the processing workflow.

## Installation

To install the framework, simply clone the repository and install the required gems:

```bash
git clone https://github.com/zedbydade/mapreduce-ruby.git
cd ruby-map-reduce
bundle install
```

## Usage

To use the framework, you need to define your map and reduce functions and start the master node. Below is an example of how to set up and run the framework:

### Require the necessary files and libraries:

```ruby
require 'grpc'
require 'logger'
require_relative 'master'
```

### Define the start function:

```ruby
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
```
### Initialize and start the master node:

```ruby
logger = Logger.new($stdout)
master = start_master(nil, 5, 40, 10, logger, 5)
logger.info(master.data)

loop do
  sleep 1
end
```

## Configuration 

The start_master function accepts the following parameters:

* _files: The input files to be processed (currently unused).
* reduce_count: The number of reduce tasks.
* worker_timeout: The timeout for worker nodes.
* worker_count: The number of worker nodes.
* logger: The logger instance for logging.
* map_count: The number of map tasks.

## License 
This project is licensed under the MIT License. See the LICENSE file for details.

