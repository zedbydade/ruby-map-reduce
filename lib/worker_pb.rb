# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: worker.proto

require 'google/protobuf'

require_relative 'server_pb'


descriptor_data = "\n\x0cworker.proto\x1a\x0cserver.proto\"-\n\rMapInfoResult\x12\x0c\n\x04uuid\x18\x01 \x01(\t\x12\x0e\n\x06result\x18\x02 \x01(\x08\"7\n\x07MapInfo\x12\x10\n\x08\x66ilename\x18\x01 \x01(\t\x12\r\n\x05\x62lock\x18\x02 \x01(\t\x12\x0b\n\x03key\x18\x03 \x01(\t\":\n\nReduceInfo\x12\x10\n\x08\x66ilename\x18\x01 \x01(\t\x12\r\n\x05\x62lock\x18\x02 \x01(\t\x12\x0b\n\x03key\x18\x03 \x01(\t2R\n\x06Worker\x12 \n\x0cMapOperation\x12\x08.MapInfo\x1a\x06.Empty\x12&\n\x0fReduceOperation\x12\x0b.ReduceInfo\x1a\x06.Emptyb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

MapInfoResult = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("MapInfoResult").msgclass
MapInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("MapInfo").msgclass
ReduceInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ReduceInfo").msgclass
