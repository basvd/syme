require "singleton"
require "ActorQueue"
require "ConnectionController"
require "eventmachine"
require "wx"
require "gui/ClientFrame"

class AppController
  include Singleton # use AppController.instance
  
  attr_reader :network_queue, :frontend_queue
  
  def initialize
    @network_queue = ActorQueue.new
    @frontend_queue = ActorQueue.new
    
    # EventMachine thread (network)
    Thread.new do
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
      Thread.pass
      @frontend_queue.process
    end
    
    # Test
    nick = "syme-irc"
    server = "irc.freenode.net"
    connect_dialog = Wx::TextEntryDialog.new(nil,
                                             :message => "Enter a connection string (nick@server) for Syme to connect to:",
                                             :caption => "Connection test",
                                             :default_value => "#{nick}@#{server}")
    if(Wx::ID_OK == connect_dialog.show_modal())
      if(connect_dialog.get_value() =~ /([^@]+)@([^:]+)/)
        nick, server= $1, $2
      end
      @network_queue.invoke_later do
        puts("Connecting...")
        ConnectionController.new(nick, server)
      end
    end
    connect_dialog.destroy()
    
    ClientFrame.new.show
  end
  
end
