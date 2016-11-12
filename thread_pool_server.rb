require 'socket'
require 'thread/pool'

# A multi-threaded TCP server supported by a thread pool.
# The default number of threads is 4.
# An optional maximum threads can be passed
class ThreadPoolServer
  def initialize(port, minimum = 4, maximum = nil)
    if maximum && maximum < minimum
      fail ArgumentError, 'Maximum threads cannot be less than minimum'
    end

    fail ArgumentError, 'Minimum threads must be greater than 0' if minimum <= 0

    @pool = Thread.pool(minimum, maximum).auto_trim!
    @server = TCPServer.open(port)
    @shutdown = false
    @shutdown_mutex = Mutex.new
  end

  def start
    loop do
      begin
        sock = @server.accept
        handle_connection(sock)
      rescue => e
        handle_shutdown(e)
        break
      end
    end
  end

  def port
    @server.addr[1]
  end

  private

  def handle_connection(sock)
    # Don't allow more connections if all threads in the pool are busy
    sock.close unless @pool.idle?

    @pool.process(sock) do |client|
      while message = client.gets
        handle_data(client, message)
      end
      client.close
    end
  end

  def shutdown
    @shutdown_mutex.synchronize do
      @shutdown = true
      @server.close
    end
  end

  def handle_shutdown(exception)
    if @shutdown
      puts 'Shutting down server'
    else
      puts 'Server shut down unexpectedly'
      puts exception
    end
    @pool.shutdown!
  end

  # @abstract Subclass is expected to implement #handle_data
  # @!method handle_data(client, message)
  #    Respond to a particular message
  def handle_data(client, message)
  end
end
