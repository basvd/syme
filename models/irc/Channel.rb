require "observer"
require "models/Chat"

class Channel < Chat

  include Observable

  attr_reader :topic, :users

  def initialize(name)
    super(name)
    @users = []
  end

  def topic=(t)
    @topic = t

    changed()
    notify_observers(self, { :topic => t })
  end

  def add_user(*usr)
    @users += usr

    changed()
    notify_observers(self, { :join => usr })
  end
end