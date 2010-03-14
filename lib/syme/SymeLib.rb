require "eventmachine"
require "logger"

# TODO: Output buffering to avoid flooding
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

  class Irc < EventMachine::Connection
    include EventMachine::Protocols::LineText2

    attr_accessor :version
    attr_reader :channels, :host, :lag, :nick, :user, :ping_timer, :supports

    def initialize(nick, args = {})
      super()

      @log = args[:logger]
      if(!@log)
        @log = Logger.new(STDOUT)
        @log.level = Logger::INFO
      end

      set_delimiter("\r\n") # IRC message delimiter

      @nick = nick
      @pass = args[:pass]
      @version = args[:version] || VERSION

      @callbacks = {}
      @channels = args[:channels]
      @ping_time = 0


      # Internal events

      on :raw do |event|
        @user = event.source_user unless event.source_user.nil? || event.source_nick != @nick
      end

      on :ctcp do |event|
        # TODO: Better CTCP
        @log.info("Received CTCP #{event.content}")
        if(event.ctcp == "VERSION")
          reply_ctcp(event.source_nick || event.source, "VERSION #{@version}")
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
      end

      on :motd_end do |event|
        @log.info("Joining channel(s)...")
        @channels.to_a.each do |c|
          join(c)
        end
      end
    end

    # Called when connection is set up
    def post_init
      @log.info("Connected!")

      @log.info("Establishing a session...")

      if(@pass)
        send_raw("PASS #{@pass}")
      end

      send_raw("NICK #{@nick}")
      send_raw("USER syme 0 * :Syme IRC")

      trigger(:connect)
    end

    def receive_line(line)
      @log.debug("<< #{line}")

      msg = MessageParser.new(line)
      event = msg.to_event()

      trigger(:incoming, event)
      trigger(event.type, event)
    end

    # Called on disconnect or connection failure
    def unbind
      @log.info("Disconnected!")
      EventMachine::stop_event_loop
    end

    def join(c)
      send_raw("JOIN #{c}")
    end

    def quit()
      send_raw("QUIT :Unjoin")
    end

    def say(c, msg)
      send_privmsg(c, msg)
    end

    # Raw IRC message
    def send_raw(msg)
      @log.debug(">> #{msg}")
      send_data("#{msg}\r\n")
    end

    # Basic CTCP send
    def send_ctcp(target, msg)
      send_privmsg(target, "\001#{MessageParser.ctcp_quote(msg)}\001")
    end

    # Basic CTCP reply
    def reply_ctcp(target, msg)
      send_notice(target, "\001#{MessageParser.ctcp_quote(msg)}\001")
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
      #event = SYM_REPLIES[event] if SYM_REPLIES.has_key?(event)
      #event = event.intern if event.respond_to?(:intern)

      @callbacks[event] = [] unless @callbacks[event].respond_to?(:each)

      @callbacks[event].each do |action|
        action.call(data)
      end
    end
  end

  class IrcEvent < Struct.new :channel, :command, :content, :ctcp, :nick, :params,
  :raw, :source, :source_nick, :source_user, :target, :type
  end

  class MessageParser

    def initialize(raw)

      @raw = raw

      # Incoming reply
      if(@raw =~ /^:([^\s]+) ([A-Z]+|\d{3})( .*)$/)
        @source = $1
        @command = $2
        params = $3

      # Outgoing command
      elsif(@raw =~ /^([A-Z]+)( .*)$/)
        @source = nil # Actually client is source
        @command = $1
        params = $2

      else
        # TODO: fail...
        return
      end

      # Split parameters (<param> {SPACE <param>} [ SPACE : <trailing>])
      params = params.split(" :", 2)
      params[0] = params[0].strip.split(/ +/) if params.size > 1
      @params = params.flatten()

      # [:channel/:nick, name]
      @target = parse_target() if has_target?

      @ctcp = parse_ctcp() if is_ctcp?

      @content = @params.last if has_trailing?

      # Find the appropriate event type
      if @command.to_i == 0
        # Convert non-numeric command to symbol
        @type = @command.downcase.intern
      else
        # Translate numeric reply
        @type = SYM_REPLIES[@command] if SYM_REPLIES.has_key?(@command)
      end

      @type = :ctcp if @type == :privmsg && is_ctcp?
    end

    def to_event()
      data = IrcEvent.new

      data.raw = @raw
      data.command = @command
      data.type = @type

      user = @source.split("!", 2)
      data.source_nick, data.source_user = user unless user.length != 2

      data.content = @params.last if has_trailing?
      data.params = @params unless @params.nil? || @params.empty?
      data.ctcp = @ctcp unless @ctcp.nil?

      # data[target_type, target]
      data[@target[0]] = @target[1] unless @target.nil?

      return data
    end

    # Contains a trailing parameter?
    def has_trailing?
      return @raw.include?(" :")
    end

    # Contains a target parameter?
    def has_target?
      case @command
      when /\d{3}/, "JOIN", "PRIVMSG", "NOTICE"
        return true
      else
        return false
      end
    end

    def is_ctcp?
      return true if @params.last =~ /\001(.*)\001/
      return false
    end

    private
    # Parses the first parameter as target
    def parse_target
      if(@command == "JOIN")
        return :channel, @params.last
      end
      name = @params[0] # Target is always first parameter (if present)
      if(name =~ /^[\#+&]/)
        return :channel, name
      else
        return :nick, name[/^[^!]+/] # Only return nickname part
      end
    end

    def parse_ctcp
      m = @params.last.match(/\001(.*)\001/)
      return MessageParser.ctcp_unquote(m[1]) unless m.nil?
    end

    public
    ## Utility methods
    # CTCP
    def self.ctcp_quote(msg)
      # Encode CTCP
      return msg.gsub(/(\020|\n|\r|\000)/) do |c|
        return "\020#{c}"
      end
    end

    def self.ctcp_unquote(msg)
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
  end
end
