require 'socket'
require './thread_pool_server'

# A server to implement the messages in Lab 2
class SimpleServer < ThreadPoolServer
  def initialize(*args)
    super(*args)
  end

  def handle_data(client, message)
    if message.start_with? 'HELO '
      response = "#{message}IP:#{server_ip}\nPort:#{port}\nStudentID:13323304\n"
      client.write(response)
    elsif message.start_with? 'KILL_SERVICE'
      shutdown
    end
  end

  private

  def server_ip
    Socket.ip_address_list.detect(&:ipv4_private?).ip_address
  end
end
