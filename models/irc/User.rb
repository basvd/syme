require "observer"

class User

  include Observable

  attr_accessor :channels, :hostname, :nick, :real_name, :user

  def initialize(nick)
    @channels = []
    @nick = nick
  end

  #def eql?(other)
  #  return @nick == other.nick if other.respond_to? :nick
  #  return @nick == other
  #end
end
