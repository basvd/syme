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
      @u_name = args[:user] || "syme"
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
        if(event.content == "VERSION")
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
      send_raw("USER #{@u_name} 0 * :Syme IRC")

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
      @callbacks[event] = [] unless @callbacks[event].respond_to?(:each)

      @callbacks[event].each do |action|
        action.call(data)
      end
    end
  end

  class MessageParser

    @@events = {} # Event classes

    attr_reader :raw, :type

    def initialize(raw)
      @raw = raw

      if(@raw =~ /^:([^\s]+) ([A-Z]+|\d{3})( .*)$/)
        # Incoming
        @source = $1
        @command = $2
        params = $3
      elsif(@raw =~ /^([A-Z]+)( .*)$/)
        # Outgoing
        @source = nil # Actually client is source
        @command = $1
        params = $2
      else
        # TODO: Throw exception
        return
      end

      # Find the appropriate event type
      if @command.to_i == 0
        # Convert non-numeric command to symbol
        @type = @command.downcase.intern
      else
        # Translate numeric reply
        @type = SYM_REPLIES[@command] if SYM_REPLIES.has_key?(@command)
      end

      # Split parameters (<param> {SPACE <param>} [ SPACE : <trailing>])
      params = params.split(" :", 2)
      if params[0].empty?
        params.shift()
      else
        params[0] = params[0].lstrip.split(/ +/)
      end
      @params = params.flatten()
      @data = {}

      #@type = :ctcp if @type == :privmsg && is_ctcp?

      # Parse source if present
      unless @source.nil?
        user = @source.split("!", 2)
        @data[:source_nick], @data[:source_user] = user unless user.length != 2
        @data[:source] = @source
      end

      # Interpret @params list, store results in @data
      case @type
      when :join, :part
        parse :channel

      when :topic_is, :no_topic
        parse :target, :channel, :topic

      when :privmsg, :notice, :motd_start, :motd, :motd_end
        parse :target, :content

      when :mode
        parse :target, :modes

      when :names_reply
        parse :target, :channel_type, :channel, :names

      end
    end

    def to_event()
      # Probably not *that* efficient for caching
      #event = (@@events[@data.keys] ||  @@events[@data.keys] = Struct.new(:raw, :command, :type, *@data.keys))
      event = Struct.new(:raw, :command, :type, *@data.keys)
      return event.new(@raw, @command, @type, *@data.values || [])
    end

    private
    def parse(*ps)
      ps.each do |p|
        str = @params.shift
        if respond_to? p, true
          # Custom parsing if possible
          send(p, str)
        else
          @data[p] = str
        end
      end
    end

    def content(str)
      if @type == :privmsg && str =~ /\001(.*)\001/
        # CTCP
        @type = :ctcp
        @data[:content] = MessageParser.ctcp_unquote($1)
      else
        @data[:content] = str
      end
    end

    def target(str)
      @data[:target] = str
      if(str =~ /^[\#+&]/)
        @data[:channel] = str
      else
        @data[:target_nick] = str
      end
    end

    def modes(str)
      @data[:modes] = {}
      @data[:params] = {}
      set = nil
      str.each_char do |c|
        if c == "+" || c == "-"
          set = (c == "+")
        else
          c = c.intern
          case c
          when :O, :o, :v, :b, :e, :I
            @data[:params][c] = @params.shift
          when :k, :l
            if set
              @data[:params][c] = @params.shift
            end
          end
          @data[:modes][c] = set
        end
      end
    end

    def names(str)
      ns = str.split(" ")
      ns.map! do |n|
        if n =~ /^([@\+])/
          case $1
          when "@"
            m = :o
          when "+"
            m = :v
          end
          [n[1..-1], m]
        else
          [n, nil]
        end
      end
      @data[:names] = ns
    end

    # Deprecated
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
