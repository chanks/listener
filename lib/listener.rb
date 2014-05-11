require 'listener/version'

class Listener
  attr_reader :connection

  def initialize(connection, options = {})
    @connection = connection
    @blocks     = {}
    @timeout    = options[:timeout] || 0.1
    @mutex      = Mutex.new
    @thread     = Thread.new { listen_loop }
  end

  def listen(*channels, &block)
    @mutex.synchronize do
      channels.each do |channel|
        if blocks = @blocks[channel.to_s]
          blocks << block
        else
          @blocks[channel.to_s] = [block]
          connection.async_exec "LISTEN #{channel}"
        end
      end
    end
  end

  def stop
    @stop = true
    @thread.join
  end

  private

  def listen_loop
    loop do
      @mutex.synchronize do
        connection.wait_for_notify(@timeout) do |channel, pid, payload|
          @blocks[channel].each { |block| block.call(channel, pid, payload) rescue nil }
        end
      end

      if @stop
        connection.async_exec "UNLISTEN *"
        {} while connection.notifies
        break
      end
    end
  end
end
