#require "eventmachine"

require "AppController"
require "lib/syme/SymeLib"
require "models/irc/Channel"
require "models/irc/Connection"
require "models/irc/Message"
require "models/irc/User"

class ConnectionController

  ERROR_CODES = (400..599).map { |i| i.to_s }

  attr_reader :model

  # Runs in network thread!
  def initialize(user, host, port = 6667, args = {})

    name = args[:name] || host
    chans = args[:channels] || []


    @app = AppController.instance
    @logger = @app.logger
    frontend = @app.frontend_queue

    @logger.info("Connecting...")
    @conn = EventMachine::connect(host, port, SymeLib::Irc,
                                  user.nick,
                                  :channels => chans,
                                  :logger => @logger,
                                  :user => user.user,
                                  :version => "Syme IRC 0.1dev")

    frontend.invoke_later do
      @model = Connection.new(self, host, user)
      @app.conn_list.add_connection(@model)
    end

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
          @model.add_channel(event.channel)
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
      frontend.invoke_later do
        @logger.debug("Names: #{event.names}")
        chat = @model.channels[event.channel]
        unless chat.nil?
          event.names.each do |name, status|
            u = User.new(name)
            chat.add_user(u)
          end
        end
      end
    end

    # Nick change
    @conn.on :nick do |event|
      frontend.invoke_later do
        source = @model.users[event.source_user]
        source.nick = event.content
      end
    end

    # Topic
    @conn.on :topic_is, :no_topic do |event|
      frontend.invoke_later do
        @model.channels[event.channel].topic = event.topic
      end
    end

    # Messages
    @conn.on :privmsg do |event|

      #target = @model.users[event.target] unless event.target.nil?
      if event.respond_to? :channel
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

  def say(msg)
    @conn.say(msg.target, msg.content)# if @model.channels.has_key? msg.target
  end

  def quit()
    @conn.quit()
  end
end
