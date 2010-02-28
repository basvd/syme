require "AppController"
require "lib/SymeLib"
require "models/irc/Channel"
require "models/irc/Connection"
require "models/irc/Message"
require "models/irc/User"

class ConnectionController

  ERROR_CODES = (400..599).map { |i| i.to_s }

  # Runs in network thread!
  def initialize(user, server, port = 6667, pass = nil)
    @app = AppController.instance
    frontend = @app.frontend_queue

    # Prepare logger for connection
    log = Logger.new(STDOUT)
    log.level = Logger::DEBUG
    log.info("Connecting...")

    frontend.invoke_later do
      @app.frame.add_chat(Channel.new(server))
    end

    @model = Connection.new(server, user)

    @conn = EventMachine::connect(server, port, SymeLib::Irc,
                                  user.nick,
                                  #:channels => ["#groept", "##groept"],
                                  :channels => "##groept",
                                  :logger => log,
                                  :version => "Syme IRC 0.1dev")

    # All errors
    @conn.on ERROR_CODES do |e|
      # TODO: Output error message
    end

    # Discover userhost
    @conn.on :raw do |event|
      user.user = @conn.user unless @conn.user.nil?
    end

    # Channel
    @conn.on :join do |event|
      if(event.source_nick == user.nick)
        frontend.invoke_later do
          @model.channels[event.channel]
          @app.frame.add_chat(@model.channels[event.channel], server)

          @model.channels[event.channel].add_observer(@app.frame.root_panel.chan_topic)
          @model.channels[event.channel].add_observer(@app.frame.root_panel.chat_box)

          log.info("Joined #{event.channel}")
        end
      else

      end
    end

    # Nick change
    @conn.on :nick do |event|
      frontend.invoke_later do
        @model.users[event.source_user]
        source = @model.users[event.source_user]
        source.nick = event.content
      end
    end

    # Topic
    @conn.on :topic_is, :no_topic do |event|
      channel = event.params[1]
      topic = event.content
      frontend.invoke_later do
        @model.channels[channel]
        @model.channels[channel].topic = topic
      end
    end

    # Messages
    @conn.on :privmsg do |event|

      #target = @model.users[event.target] unless event.target.nil?
      if(!event.channel.nil?)
        # Channel message
        frontend.invoke_later do
          @model.users[event.source_user]
          source = @model.users[event.source_user]
          source.nick = event.source_nick if source.nick.nil?

          msg = Message.new(source, event.target, event.content, type = nil)
          @model.channels[event.channel]
          @model.channels[event.channel].add_message(msg)
        end
      else
        # TODO: Private chat
        frontend.invoke_later do
          #@model.privates[event.source]
          #@model.privates[event.source].add_message(msg)
        end
      end
    end
  end
end
