require "eventmachine"

# Future SymeLib?

class Irc < EventMachine::Connection
  include EventMachine::Protocols::LineText2
  
  def initialize
    super()
    set_delimiter("\r\n") # IRC message delimiter
  end
  
  # Called when connection is set up
  def post_init
    send_data("connected!")
  end
  
  # Called when connection received something
  def receive_line(line)
    send_data("received line: #{line}")
  end
  
  # Called on disconnect or connection failure
  def unbind
    #puts("Connection terminated.")
    EventMachine::stop_event_loop
  end
end