require "singleton"
require "ActorQueue"
require "eventmachine"
require "lib/SymeLib"

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
    Wx::Timer.every(55) do
      Thread.pass
      @frontend_queue.process
    end
    
    # Test
    nick = "syme-irc"
    server = "irc.freenode.net"
    port = 6667
    connect_dialog = Wx::TextEntryDialog.new(nil,
                                             :message => "Enter a connection string (nick@server:port) for Syme to connect to:",
                                             :caption => "Connection test",
                                             :default_value => "#{nick}@#{server}:#{port}")
    if(Wx::ID_OK == connect_dialog.show_modal())
      if(connect_dialog.get_value() =~ /([^@]+)@([^:]+):(\d+)/)
        nick, server, port = $1, $2, $3.to_i
      end
      @network_queue.invoke_later do
        puts("Connecting...")
        EventMachine.connect server, port, SymeLib::Irc, nick
      end
    end
    connect_dialog.destroy()
  end
  
end
