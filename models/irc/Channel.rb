require "observer"
require "ostruct"
require "models/Chat"

class Channel < Chat

  include Observable

  attr_reader :modes, :topic, :users

  def initialize(conn, name, modes = {})
    super(conn, name)
    # Flexible structure seems appropriate
    modes.merge!({:o => [], :v => [], :b => []})
    @modes = OpenStruct.new(modes)
    @users = []
  end

  def topic=(t)
    @topic = t

    changed()
    notify_observers(self, { :topic => t })
  end

  def add_user(u)
    unless @users.include? u
      @users.push(u)
      changed()
      notify_observers(self, { :add_user => u })
    end
  end

  # Should be called every time one or more mode changes have been done
  # FIXME: This is probably a workaround
  def modes_changed()
    changed()
    notify_observers(self, { :modes => @modes })
  end
end
