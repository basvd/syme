require "observer"

class Channel

  include Observable

  attr_reader :name, :topic, :users

  def initialize(name)
    @name = name
    @messages = []
    @users = []
  end

  def topic=(t)
    @topic = t
    
    changed()
    notify_observers({ :topic => t })
  end

  def add_message(*msg)
    @messages += msg

    changed()
    notify_observers({ :messages => msg })
  end

  def add_user(*usr)
    @users += usr

    changed()
    notify_observers({ :join => usr })
  end
end
