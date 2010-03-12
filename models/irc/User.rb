require "observer"

class User

  include Observable

  attr_accessor :nick, :user, :real_name

  def initialize(nick = nil, user = nil)
    @nick = nick
    @user = user
  end
end
