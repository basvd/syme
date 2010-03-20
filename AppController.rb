require "logger"
require "singleton"
require "wx"

require "ActorQueue"
require "ConnectionController"
require "gui/ClientFrame"
require "gui/dialogs/ConnectDialog"
require "models/ConnectionList"
require "models/irc/User"

class AppController
  include Singleton # use AppController.instance

  attr_reader :conn_list, :frame, :frontend_queue, :logger, :network_queue

  def initialize
    # Prepare logger for connection
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

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

    # Present connection dialog
    @conn_dlg = ConnectDialog.new(@frame)
    on_menu_conn()
  end

  def on_menu_conn(event = nil)
    if Wx::ID_OK == @conn_dlg.show_modal()
      name = @conn_dlg.name
      host, port = @conn_dlg.host, @conn_dlg.port
      nick, user = @conn_dlg.nick, @conn_dlg.user
      channels = @conn_dlg.channels
      u = User.new(nick)
      u.user = user

      @network_queue.invoke_later do
        ConnectionController.new(u,
                                 host, port,
                                 :name => name,
                                 :channels => channels)
      end
    end
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

  # Main window is being closed
  def on_close(event)
    close_dialog = Wx::MessageDialog.new(@frame,
                                         :message => "Do you want to close Syme?",
                                         :caption => "Quit Syme",
                                         :style => Wx::YES | Wx::NO | Wx::NO_DEFAULT)
    if close_dialog.show_modal() == Wx::ID_YES
      @network_queue.invoke_later do
        @conn_list.connections.each do |c|
          c.con.quit()
        end
        EventMachine::stop_event_loop()
      end
      @net.join() if @net.alive?
      event.skip()
    else
      event.veto()
    end
  end

  # Application is exiting
  def on_exit
    # FIXME: Strange behaviour, called twice and disconnects before QUIT message
    exit()
  end
end
