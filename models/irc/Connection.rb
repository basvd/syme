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
    @users = {}
    @u_ref = Hash.new(0)
  end

  def add_channel(chat)
    c = @channels[chat] = Channel.new(@con, chat)

    changed()
    notify_observers(self, { :add_channel => c })
  end

  def add_private(chat)
    c = @privates[chat] = Chat.new(@con, chat) # TODO: PrivateChat

    changed()
    notify_observers(self, { :add_private => c })
  end

  def delete_channel(c)
    unless @channels.delete(c).nil?
      changed()
      notify_observers(self, { :delete_channel => c })
    end
  end

  def delete_private(chat)
    # TODO
  end

  def add_user(u, chan = nil)
    @users[u.nick] = u unless @users.has_key? u.nick
    unless chan.nil?
      @u_ref[u] = @u_ref[u] + 1
      @channels[chan].add_user(u)
    end
  end

  def delete_user(u, chan = nil)
    if @channels.has_key? chan
      @u_ref[u] = @u_ref[u] - 1 if @channels[chan].delete_user(u)
    end
    @users.delete(u.nick) if chan.nil?# || @u_ref[u] == 0
  end
end
