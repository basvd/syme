require "observer"

class Chat

  include Observable

  attr_reader :conn, :messages, :name

  def initialize(conn, name)
    @conn = conn
    @name = name
    @messages = []
  end

  def add_message(msg)
    @messages.push(msg)

    changed()
    notify_observers(self, { :add_message => msg })
  end

  def profile
    return @conn.model.profile
  end
end
