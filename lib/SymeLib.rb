require "eventmachine"
require "logger"

module SymeLib
  
  NUM_REPLIES = {
    :yourhost => "002",
    :endofmotd => "376"
  }
  
  SYM_REPLIES = NUM_REPLIES.invert()
  
  class IrcEvent
    attr_reader :command, :source, :src_nick, :target, :tgt_nick, :channel, :content
    
    def initialize(command, source, target = nil, content = nil)
      @command = command
      @source = source
      @src_nick = source.index("!").nil? ? source : source[0..source.index("!")-1]
      @target = target
      @tgt_nick = target.index("!").nil? ? target : target[0..target.index("!")-1]
      @content = content
      #@channel = @target if target.index("!").nil?
    end
  end
  
  class Irc < EventMachine::Connection
    include EventMachine::Protocols::LineText2
    
    attr_accessor :version
    attr_reader :ping_timer, :lag, :host
    
    def initialize(nick, pass = nil)
      super()
      
      @log = Logger.new(STDOUT)
      @log.level = Logger::INFO
      
      set_delimiter("\r\n") # IRC message delimiter
      
      @pass = pass
      @nick = nick
      @callbacks = {}
      @ping_time = 0
      @version = "Syme #{SYME_VERSION}"
      
      # TODO: Better CTCP
      on :ctcp do |event|
        @log.debug("CTCP #{event.content}")
        if(event.content == "VERSION")
          reply_ctcp(event.src_nick, "VERSION #{@version}")
        end
      end
      
      on :yourhost do |event|
        # PING regularly to keep connection alive
        @ping_timer = @ping_timer || EventMachine::PeriodicTimer.new(30) do
          @ping_time = Time.now.to_f
          send_raw("PING #{@host}")
        end
      end
      
      on :ping do |event|
        send_raw("PONG #{event.content}")
      end
      
      on :endofmotd do |event|
        @log.info("Joining channel(s)...")
        send_raw("JOIN ##groept") # TODO: Change dummy channel
      end
    end
    
    # Called when connection is set up
    def post_init
      @log.info("Connected!")
      trigger(:connected)
      
      @log.info("Establishing a session...")
      trigger(:login)
      
      if(@pass)
        send_raw("PASS #{@pass}")
      end
      
      send_raw("NICK #{@nick}")
      send_raw("USER syme 0 * :Syme IRC")
    end
    
    def receive_line(line)
      @log.debug("<< #{line}")
      
      if(line =~ /^:([^\s]+) ([A-Z]+|\d{3}) ([^\s]+)\s*:?(.*)$/)
        if $2.to_i == 0
          command = $2.downcase.intern
        else
          command = $2
          command = SYM_REPLIES[command] if SYM_REPLIES.has_key?(command)
        end
        source = $1
        target = $3
        content = $4
        
        case(command)
        
        when :ping
          content = $3
          target = nil
        
        when :pong
          @lag = Time.now.to_f - @ping_time
          @log.info("Ping (s): #{@lag}")
          
        when :privmsg
          if(content =~ /\001(.*)\001/)
            command = :ctcp
            content = ctcp_unquote($1)
          end
        
        when :yourhost
          @host = source
        
        end
        
        event = IrcEvent.new(command, source, target, content)
        trigger(:receive, event)
        trigger(command, event)
      end
    end
    
    # Called on disconnect or connection failure
    def unbind
      @log.info("Disconnected!")
      EventMachine::stop_event_loop
    end
    
    def ctcp_quote(msg)
      # Encode CTCP
      return msg.gsub(/(\020|\n|\r|\000)/) do |c|
        return "\020#{c}"
      end
    end
    
    def ctcp_unquote(msg)
      # Decode CTCP
      return msg.gsub(/\020(\020|n|r|0)/) do |c|
        case(c)
        when "n"
          return "\n"
        when "r"
          return "\r"
        when "0"
          return "\000"
        end
        return "\020"
      end
    end
    
    # Raw IRC message
    def send_raw(msg)
      @log.debug(">> #{msg}")
      send_data("#{msg}\r\n")
    end
    
    # Basic CTCP send
    def send_ctcp(target, msg)
      send_privmsg(target, "\001#{ctcp_quote(msg)}\001")
    end
    
    # Basic CTCP reply
    def reply_ctcp(target, msg)
      send_notice(target, "\001#{ctcp_quote(msg)}\001")
    end
    
    def send_notice(target, msg)
      send_raw("NOTICE #{target} :#{msg}")
    end
    
    def send_privmsg(target, msg)
      send_raw("PRIVMSG #{target} :#{msg}")
    end
    
    # Register callback for an event
    def on(event, &action)
      event = NUM_REPLIES[event] if NUM_REPLIES.has_key?(event)
      event = event.intern if event.respond_to?(:intern)
      
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:push)
      
      @callbacks[event].push(action)
    end
    
    def trigger(event, data = nil)
      event = NUM_REPLIES[event] if NUM_REPLIES.has_key?(event)
      event = event.intern if event.respond_to?(:intern)
      
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:each)
      
      @callbacks[event].each do |action|
        action.call(data)
      end
    end
  end
end