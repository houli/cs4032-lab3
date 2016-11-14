# A class to handle a chat room with multiple connected users
class ChatRoom
  attr_reader :name, :reference

  def initialize(name, reference)
    @users = {}
    @name = name
    @reference = reference
  end

  def add_user(user_name, socket)
    @users[socket] = user_name unless @users.include?(socket)
    send_message("#{user_name} has joined this chatroom.", socket)
  end

  def remove_user(user_name, socket)
    send_message("#{user_name} has left this chatroom.", socket)
    @users.delete(socket)
  end

  def disconnect_user(socket)
    remove_user(@users[socket], socket) if @users.include?(socket)
  end

  def send_message(message, from_socket)
    user_name = @users[from_socket]
    @users.keys.each do |user|
      response = "CHAT:#{reference}\nCLIENT_NAME:#{user_name}\nMESSAGE:#{message}\n\n"
      user.write(response)
    end
  end
end
