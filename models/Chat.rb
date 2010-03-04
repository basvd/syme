
class Chat

  include Observable

  attr_reader :messages, :name

  def initialize(name)
    @name = name
    @messages = []
  end

  def add_message(*msg)
    @messages += msg

    changed()
    notify_observers(self, { :messages => msg })
  end
end
