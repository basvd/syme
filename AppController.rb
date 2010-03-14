require "logger"
require "singleton"
require "wx"

require "ActorQueue"
require "ConnectionController"
require "gui/ClientFrame"
require "models/ConnectionList"
require "models/irc/User"

class AppController
  include Singleton # use AppController.instance

  attr_reader :conn_list, :frame, :frontend_queue, :logger, :network_queue

  def initialize
    # Prepare logger for connection
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::ERROR

    @conn_list = ConnectionList.new

    @frame = ClientFrame.new(self)
    @frontend_queue = ActorQueue.new
    @network_queue = ActorQueue.new

    # GUI observes connections
    @conn_list.add_observer(@frame)

    # EventMachine thread (network)
    @net = Thread.new do
      EventMachine::run do
        # Process actors on every tick
        on_tick = proc do
          @network_queue.process
          EventMachine::next_tick(on_tick)
        end
        on_tick.call
      end
    end

    # Run other thread and process actors (frontend)
    Wx::Timer.every(25) do
      Thread.pass()
      @frontend_queue.process
    end

    @frame.show()

    # Test
    nick = "syme-irc"
    server = "irc.freenode.net"
    connect_dialog = Wx::TextEntryDialog.new(@frame,
                                             :message => "Enter a connection string (nick@server) for Syme to connect to:",
                                             :caption => "Connection test",
                                             :default_value => "#{nick}@#{server}")
    if Wx::ID_OK == connect_dialog.show_modal()
      if(connect_dialog.get_value() =~ /([^@]+)@([^:]+)/)
        nick, server= $1, $2
      end
      @network_queue.invoke_later do
        ConnectionController.new(User.new(nick), server)
      end
    end
    connect_dialog.destroy()
  end

  # Input received from chat window
  def on_chat_command(event)
    control = event.event_object
    c = @frame.current_chat
    if c.is_a? Channel
      msg = Message.new(c.profile, c.name, control.value)
      c.conn.say(msg)
      c.add_message(msg)
    end
  end

  # Application is being closed
  def on_close(event)
    close_dialog = Wx::MessageDialog.new(@frame,
                                         :message => "Do you want to close Syme?",
                                         :caption => "Quit Syme",
                                         :style => Wx::YES | Wx::NO)
    if close_dialog.show_modal() == Wx::ID_YES
      @network_queue.invoke_later do
        @conn_list.connections.each do |c|
          c.con.quit()
        end
      end
      @net.join()
      @frame.destroy()
      exit()
    else
      event.veto()
    end
  end
end
