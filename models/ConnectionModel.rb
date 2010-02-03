require "observer"

class ConnectionModel
  
  include Observable
  
  def initialize(sv_name, id)
    super()
    @server_name = sv_name
    @identity = id
    @chats = []
  end
  
  def add_chat(chat_model)
    change = { :add => [] }
    chat_model = [chat_model].flatten
    
    chat_model.each do |m|
      @chats.push(m)
      change[:add].push(m)
    end
    
    changed()
    notify_observers(change)
  end
  
  def delete_chat(chat_model)
    change = { :delete => [] }
    chat_model = [chat_model].flatten
   
    chat_model.each do |m|
      @chats.delete(m)
      change[:delete].push(m)
    end
    
    changed()
    notify_observers(change)
  end
  
end
