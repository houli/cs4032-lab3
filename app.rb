require './chat_server'

# Start chat server with minimum 4 threads, maximum 12 threads
ChatServer.new(ARGV[0], 4, 12).start
