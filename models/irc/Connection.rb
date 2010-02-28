require "observer"

class Connection

  include Observable

  attr_reader :channels, :privates, :users

  def initialize(sv_name, id)
    super()
    @server_name = sv_name
    @identity = id

    @channels = Hash.new do |hash, key|
      hash[key] = Channel.new(key)

      changed()
      notify_observers(:channels)
    end

    @privates = Hash.new #do |hash, key|
    #  hash[key] = PrivateChat.new(key)

    #  changed()
    #  notify_observers(:privates)
    #end

    @users = Hash.new do |hash, key|
      hash[key] = User.new(nil, key)
    end
  end

  def add_user(usr, chan = nil)
    @users[usr.user] = usr
    @channels[chan].add_user(usr) unless chan.nil?
  end
end
