
class Message

  attr_reader :time, :source, :source_nick, :target, :content, :type

  def initialize(source, target, content, type = nil)
  #def initialize(event, type = nil)
    @time = Time.now

    @source = source # User | nil
    @source_nick = source.nick unless source.nil? # String | nil

    @target = target # User | Channel | nil
    @content = content  # String
    @type = type
  end
end
