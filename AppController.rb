require "singleton"
require "ActorQueue"
require "eventmachine"
require "lib/Irc"

class AppController
  include Singleton # use AppController.instance
  
  attr_reader :network_queue, :frontend_queue
  
  def initialize
    @network_queue = ActorQueue.new
    @frontend_queue = ActorQueue.new
    
    # EventMachine thread (network)
    Thread.new do
      EventMachine::run do
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
    
    @network_queue.invoke_later do
      EventMachine.connect "localhost", 6667, Irc
    end
  end
  
end
