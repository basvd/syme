require "observer"

class Connection

  include Observable

  attr_reader :channels, :chat, :con, :host, :privates, :profile, :users

  def initialize(con, server, id)
    @con = con
    @host = server
    @profile = id

    # Chat for connection messages
    @chat = Chat.new(@con, @host)

    # Active chats
    @channels = {}
    @privates = {}

    # User lookup table
    @users = Hash.new do |hash, key|
      hash[key] = User.new(nil, key)
    end
  end

  def add_channel(chat)
    c = @channels[chat] = Channel.new(@con, chat)

    changed()
    notify_observers(self, { :add_channel => c })
  end

  def add_private(chat)
    @privates[chat.name] = chat

    changed()
    notify_observers(self, { :add_private => chat })
  end

  def delete_channel(c)
    c = @channels.delete(c)

    unless c.nil?
      changed()
      notify_observers(self, { :delete_channel => c })
    end
  end

  def delete_private(chat)
    # TODO
  end

  def add_user(usr, chan = nil)
    @users[usr.user] = usr
    @channels[chan].add_user(usr) unless chan.nil?
  end
end
