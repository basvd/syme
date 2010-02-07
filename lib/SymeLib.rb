require "eventmachine"

module SymeLib
  
  class IrcEvent
    attr_accessor :command, :content
    
    def initialize(command, content)
      @command = command
      @content = content
    end
  end
  
  class Irc < EventMachine::Connection
    include EventMachine::Protocols::LineText2
    
    def initialize(nick, pass = nil)
      super()
      
      set_delimiter("\r\n") # IRC message delimiter
      
      @pass = pass
      @nick = nick
      @callbacks = {}
      
      on :endofmotd do |event|
        send_raw("JOIN #groept")
      end
      
      puts("Irc module initialized!")
    end
    
    # Called when connection is set up
    def post_init
      puts("Connected!")
      puts("Establishing a session...")
      
      if(@pass)
        send_raw("PASS #{@pass}")
      end
      
      send_raw("NICK #{@nick}")
      send_raw("USER syme 0 * :Syme IRC")
      
      # PING regularly to keep connection alive
      EventMachine::PeriodicTimer.new(30) do
        send_raw("PING #{@host}")
      end
    end
    
    # Called when connection received something
    def receive_line(line)
      puts("<< #{line}")
      
      case(line)
      
      # PING
      when /^:([^\s]+) PING ([^\s]+)/
        send_raw("PONG #{$2}")
        trigger(:ping, IrcEvent.new($1, $2))
      
      # YOURHOST
      when /^:([^\s]+) 002 /
        @host = $1
        trigger(:yourhost, IrcEvent.new($1, nil))
      
      # ENDOFMOTD
      when /^:([^\s]+) 376 /
        trigger(:endofmotd, IrcEvent.new($1, nil))
        
      end
    end
    
    # Called on disconnect or connection failure
    def unbind
      puts("Disconnected!")
      EventMachine::stop_event_loop
    end
    
    # Raw IRC message
    def send_raw(msg)
      puts(">> #{msg}")
      send_data("#{msg}\r\n")
    end
    
    def on(event, &action)
      event = event.intern if event.respond_to?(:intern)
      
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:push)
      
      @callbacks[event].push(action)
    end
    
    def trigger(event, data)
      event = event.intern if event.respond_to?(:intern)
      
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:each)
      
      @callbacks[event].each do |action|
        action.call(data)
      end
    end
  end
end