require "eventmachine"
require "logger"

module SymeLib
  # Default CTCP VERSION reply
  VERSION = "SymeLib 0.1"
  
  # Event names <-> Numeric replies
  NUM_REPLIES = {
    :your_host => "002",
    :motd_start => "375",
    :motd => "372",
    :motd_end => "376",
    :no_topic => "331",
    :topic_is => "332",
    :names_reply => "353",
    :names_end => "366"
  }
  
  SYM_REPLIES = NUM_REPLIES.invert()
  
  class IrcEvent
    attr_reader :command, :source, :src_nick, :target, :tgt_nick, :channel, :content
    
    def initialize(source, command, args)
      @command = command
      @source = source
      
      @target = args[:target]
      @content = args[:content]
      
      # Extract nickname
      #@source[:nick], @source[:user] = @source.split("!", 2) unless @source.index("!").nil?
      #@target[:nick], @source[:nick] = @target.split("!", 2) unless @target.index("!").nil?
      
      @channel = args[:channel]
    end
  end
  
  class Irc < EventMachine::Connection
    include EventMachine::Protocols::LineText2
    
    attr_accessor :version
    attr_reader :ping_timer, :lag, :host
    
    def initialize(nick, args = {})
      super()
      
      @log = args[:logger]
      if(!@log)
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
      end
      
      set_delimiter("\r\n") # IRC message delimiter
      
      @pass = args[:pass]
      @nick = nick
      @callbacks = {}
      @ping_time = 0
      @version = args[:version] || VERSION
      
      # Internal events
      
      on :ctcp do |event|
        # TODO: Better CTCP
        @log.debug("CTCP #{event.content}")
        if(event.content == "VERSION")
          reply_ctcp(event.source[/^[^!]+/], "VERSION #{@version}")
        end
      end
      
      on :your_host do |event|
        @host = event.source
        # PING regularly to keep connection alive
        @ping_timer = @ping_timer || EventMachine::PeriodicTimer.new(args[:ping] || 30) do
          @ping_time = Time.now.to_f
          send_raw("PING #{@host}")
        end
      end
      
      on :ping do |event|
        send_raw("PONG #{event.content}")
      end
      
      on :pong do |event|
        @lag = Time.now.to_f - @ping_time
        @log.info("Ping (s): #{@lag}")
      end
      
      on :motd_end do |event|
        @log.info("Joining channel(s)...")
        send_raw("JOIN ##groept") # TODO: Change dummy channel
      end
    end
    
    # Called when connection is set up
    def post_init
      @log.info("Connected!")
      #trigger(:connected)
      
      @log.info("Establishing a session...")
      #trigger(:login)
      
      if(@pass)
        send_raw("PASS #{@pass}")
      end
      
      send_raw("NICK #{@nick}")
      send_raw("USER syme 0 * :Syme IRC")
    end
    
    def receive_line(line)
      @log.debug("<< #{line}")
      
      if(line =~ /^:([^\s]+) ([A-Z]+|\d{3}) (.*)$/)
        
        source = $1
        command = $2
        #target = $3
        content = $3
        
        if command.to_i == 0
          # Convert non-numeric command to symbol
          event = command.downcase.intern
        else
          # Translate numeric reply
          event = SYM_REPLIES[command] if SYM_REPLIES.has_key?(command)
        end
        
        # TODO: Parse `content` if necessary (especially `target`)
        case command
        
        when "PRIVMSG"
          if(content =~ /\001(.*)\001/)
            event = :ctcp
            content = ctcp_unquote($1)
          end
        
        end
        
        data = IrcEvent.new(source, command,
                            #:target => target,
                            :content => content)
        trigger(event, data)
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
    
    # Register callback for a list of events (or just one, of course)
    def on(*evts, &action)
      evts.each do |event|
        # If necessary, translate numeric or string event to symbol
        event = SYM_REPLIES[event] if SYM_REPLIES.has_key?(event)
        event = event.intern if event.respond_to?(:intern)
        
        @callbacks[event] = [] unless @callbacks[event].respond_to?(:push)
        
        @callbacks[event].push(action)
      end
    end
    
    private
    def trigger(event, data = nil)
      # If necessary, translate numeric or string event to symbol
      event = SYM_REPLIES[event] if SYM_REPLIES.has_key?(event)
      event = event.intern if event.respond_to?(:intern)
      
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:each)
      
      @callbacks[event].each do |action|
        action.call(data)
      end
    end
  end
end