require "observer"

class ChatModel < Model
  
  include Observable
  
  def initialize(name, type = :channel)
    @name = name
    @type = type
    @messages = []
  end
end
