require 'socket'
require './chat_room'
require './thread_pool_server'

# A chat server to implement the messages in Lab 3
class ChatServer < ThreadPoolServer
  def initialize(*args)
    super(*args)
    @rooms = []
    @users = {}

    @user_reference_mutex = Mutex.new
    @user_reference = 0
    @room_reference_mutex = Mutex.new
    @room_reference = 0
  end

  def handle_data(client, message)
    puts message
    if message.start_with? 'HELO '
      handle_hello(client, message)
    elsif message.start_with? 'KILL_SERVICE'
      shutdown
    elsif message.start_with? 'JOIN_CHATROOM'
      handle_join(client, data(message))
    elsif message.start_with? 'LEAVE_CHATROOM'
      handle_leave(client, data(message).to_i)
    elsif message.start_with? 'DISCONNECT'
      handle_disconnect(client)
    elsif message.start_with? 'CHAT'
      handle_chat(client, data(message).to_i)
    else
      puts 'Invalid message received'
    end
  end

  private

  def data(message)
    message.split(':')[1].strip
  end

  def handle_hello(client, message)
    response = "#{message}IP:#{server_ip}\nPort:#{port}\nStudentID:13323304\n"
    client.write(response)
  end

  def handle_join(client, room_name)
    2.times { client.gets } # Skip over client IP and port

    room = room_by_name(room_name)

    user_name = data(client.gets)
    user_reference = user_by_socket(client)

    response = "JOINED_CHATROOM:#{room_name}\nSERVER_IP:#{server_ip}\nPORT:#{port}\nROOM_REF:#{room.reference}\nJOIN_ID:#{user_reference}\n"
    client.write(response)
    room.add_user(user_name, client)
  end

  def handle_leave(client, room_reference)
    user_reference = data(client.gets)
    user_name = data(client.gets)

    response = "LEFT_CHATROOM:#{room_reference}\nJOIN_ID:#{user_reference}\n"
    client.write(response)
    room_by_reference(room_reference).remove_user(user_name, client)
  end

  def handle_disconnect(client)
    2.times { client.gets } # Skip over port and client name
    @rooms.each { |room| room.disconnect_user(client) }
    @users.delete(client)
    client.close
  end

  def handle_chat(client, room_reference)
    2.times { client.gets } # Skip over client id and name
    message = data(client.gets)
    client.gets # Skip over second newline in message
    room_by_reference(room_reference).send_message(message, client)
  end

  def room_by_name(room_name)
    found_room = @rooms.find { |room| room.name == room_name }
    if found_room.nil?
      # Create a new room if it doesn't exist
      found_room = ChatRoom.new(room_name, new_room_reference)
      @rooms << found_room
    end
    found_room
  end

  def room_by_reference(room_reference)
    @rooms.find { |room| room.reference == room_reference }
  end

  def user_by_socket(socket)
    if @users.include?(socket)
      return @users[socket]
    else
      reference = new_user_reference
      @users[socket] = reference
      return reference
    end
  end

  def new_user_reference
    @user_reference_mutex.synchronize do
      old_val = @user_reference
      @user_reference += 1
      return old_val
    end
  end

  def new_room_reference
    @room_reference_mutex.synchronize do
      old_val = @room_reference
      @room_reference += 1
      return old_val
    end
  end

  def server_ip
    Socket.ip_address_list.detect(&:ipv4_private?).ip_address
  end
end
