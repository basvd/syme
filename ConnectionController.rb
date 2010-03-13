#require "eventmachine"

require "AppController"
require "lib/syme/SymeLib"
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

    @logger = @app.logger

    @model = Connection.new(server, user)

    frontend.invoke_later do
      @app.conn_list.add_connection(@model)
    end

    @logger.info("Connecting...")
    @conn = EventMachine::connect(server, port, SymeLib::Irc,
                                  user.nick,
                                  #:channels => ["#groept", "##groept"],
                                  :channels => "##groept",
                                  :logger => @logger,
                                  :version => "Syme IRC 0.1dev")

    # All errors
    @conn.on ERROR_CODES do |event|
      # TODO: Output error message
    end

    # Discover userhost
    @conn.on :raw do |event|
      user.user = @conn.user unless @conn.user.nil?
    end

    # MOTD
    @conn.on :motd_start, :motd, :motd_end do |event|
      frontend.invoke_later do
          @model.users["*"]
          source = @model.users["*"]

          msg = Message.new(source, event.target, event.content, event.type)
          @model.chat.add_message(msg)
        end
    end

    # Channel
    @conn.on :join do |event|
      if(event.source_nick == user.nick)
        frontend.invoke_later do
          chat = Channel.new(event.channel)
          @model.add_channel(chat)

          @logger.info("Joined #{event.channel}")
        end
      else
        frontend.invoke_later do
          chat = @model.channels[event.channel]
          unless chat.nil?
            u = User.new(event.source_nick, event.source_user)
            chat.add_user(u)
          end

          @logger.info("#{u.nick} joined #{event.channel}")
        end
      end
    end

    # Users
    @conn.on :names_reply do |event|

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
