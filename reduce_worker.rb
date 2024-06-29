require 'securerandom'

class ReduceWorker
  def initialize
    @uuid = SecureRandom.uuid
    @idle = false
  end

  attr_reader :uuid
  attr_accessor :idle
end
