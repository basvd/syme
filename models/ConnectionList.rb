require "observer"

class ConnectionList

  include Observable

  attr_reader :connections

  def initialize()
    @connections = []
  end

  def add_connection(conn)
    @connections.push(conn)

    changed()
    notify_observers(self, { :add_connection => conn })
  end

  def delete_connection(conn)
    conn = @connections.delete(conn)

    unless conn.nil?
      changed()
      notify_observers(self, { :delete => conn })
    end
  end
end
