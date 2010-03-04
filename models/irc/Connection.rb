require "observer"

class Connection

  include Observable

  attr_reader :channels, :chat, :privates, :users

  def initialize(sv_name, id)
    super()
    @server_name = sv_name
    @identity = id

    # Chat for connection messages
    @chat = Chat.new(@server_name)

    # Active chats
    @channels = {}
    @privates = {}

    # User lookup table
    @users = Hash.new do |hash, key|
      hash[key] = User.new(nil, key)
    end
  end

  def add_channel(chat)
    @channels[chat.name] = chat

    changed()
    notify_observers(self, { :add_channel => chat })
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
