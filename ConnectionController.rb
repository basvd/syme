require "AppController"
require "lib/SymeLib"
require "models/ConnectionModel"

class ConnectionController
  
  attr_reader :connection, :conn_model
  
  def initialize(identity, server, port = 6667, pass = nil)
    @app = AppController.instance
    
    # TODO: Use identity like an Identity object instead of string
    @connection = EventMachine::connect(server, port, SymeLib::Irc, identity, pass)
    @model = ConnectionModel.new(server, identity)
    
    @app.frontend_queue.invoke_later do
      # TODO: Update model with self
    end
    
    @connection.on :receive do |event|
      # TODO: Output the message
    end
  end
end
