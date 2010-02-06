
class ActorQueue
  
  def initialize
    @queue = []
    @mutex = Mutex.new
  end
  
  def process
    @mutex.synchronize do
      while(!@queue.empty?)
        actor = @queue.shift()
        actor.call
      end
    end
  end
  
  def invoke_later(&actor)
    @mutex.synchronize do
      @queue.push(actor)
    end
  end
end
