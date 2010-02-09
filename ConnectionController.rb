require "AppController"
require "lib/SymeLib"
require "models/ConnectionModel"

class ConnectionController
  
  ERROR_CODES = (400..599).map { |i| i.to_s }
  
  attr_reader :connection, :conn_model
  
  def initialize(identity, server, port = 6667, pass = nil)
    @app = AppController.instance
    
    # Prepare logger for connection
    log = Logger.new(STDOUT)
    log.level = Logger::DEBUG
    log.info("Connecting...")
    
    # TODO: Use identity like an Identity object instead of string
    @conn = EventMachine::connect(server, port, SymeLib::Irc,
                                  identity,
                                  :version => "Syme IRC 0.1dev",
                                  :logger => log)
    
    #@model = ConnectionModel.new(server, identity)
    
    @app.frontend_queue.invoke_later do
      # TODO: Update model with self
    end
    
    # All errors
    @conn.on ERROR_CODES do |event|
      # TODO: Output error message
      event_to_chat(event)
    end
    
    @conn.on :privmsg, :topic_is do |event|
      # TODO: Output the message
      event_to_chat(event)
    end
  end
  
  def event_to_chat(event)
    # TODO: Update approp. ChatModel based on event (in main thread!)
    #@app.frontend_queue.invoke_later do
    #end
  end
end
