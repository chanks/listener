require 'listener/version'

class Listener
  attr_reader :connection

  def initialize(connection, options = {})
    @timeout  = options[:timeout] || 0.1

    @blocks      = {}
    @block_mutex = Mutex.new

    @connection       = connection
    @connection_mutex = Mutex.new

    @thread = Thread.new { listen_loop }
    @thread.priority = options[:priority] || 1
  end

  def listen(*channels, &block)
    to_listen = []

    @block_mutex.synchronize do
      channels.each do |channel|
        channel = channel.to_s

        if blocks = @blocks[channel]
          blocks << block
        else
          @blocks[channel] = [block]
          to_listen << channel
        end
      end
    end

    if to_listen.any?
      @connection_mutex.synchronize do
        connection.async_exec to_listen.map{|c| "LISTEN #{c}"}.join('; ')
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
      if notification = retrieve_notification
        blocks_for_channel(notification.first).each do |block|
          block.call(*notification) rescue nil
        end
      end

      if @stop
        @connection_mutex.synchronize do
          connection.async_exec "UNLISTEN *"
          {} while connection.notifies
        end

        break
      end
    end
  end

  def blocks_for_channel(channel)
    @block_mutex.synchronize { @blocks[channel].dup }
  end

  def retrieve_notification
    @connection_mutex.synchronize do
      connection.wait_for_notify(@timeout) { |*args| return args }
    end
  end
end
