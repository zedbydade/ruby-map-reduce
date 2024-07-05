# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: server.proto

require 'google/protobuf'


descriptor_data = "\n\x0cserver.proto\"\x07\n\x05\x45mpty\"=\n\nWorkerInfo\x12\x0c\n\x04uuid\x18\x01 \x01(\t\x12\x0f\n\x07success\x18\x02 \x01(\t\x12\x10\n\x08\x66ilename\x18\x03 \x01(\t\"&\n\x14RegisterWorkerResult\x12\x0e\n\x06result\x18\x01 \x01(\x08\"?\n\x15RegisterWorkerRequest\x12\x0c\n\x04uuid\x18\x01 \x01(\t\x12\n\n\x02ip\x18\x02 \x01(\t\x12\x0c\n\x04type\x18\x03 \x01(\t2q\n\x0fMapReduceMaster\x12\x41\n\x0eRegisterWorker\x12\x16.RegisterWorkerRequest\x1a\x15.RegisterWorkerResult\"\x00\x12\x1b\n\x04Ping\x12\x0b.WorkerInfo\x1a\x06.Emptyb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

Empty = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Empty").msgclass
WorkerInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("WorkerInfo").msgclass
RegisterWorkerResult = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("RegisterWorkerResult").msgclass
RegisterWorkerRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("RegisterWorkerRequest").msgclass
