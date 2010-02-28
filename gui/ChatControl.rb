require "wx"
require "models/irc/Message.rb"

# TODO: Implement a custom control using scrollbar and canvas of some sort
class ChatControl < Wx::StyledTextCtrl

  STYLES = { :time => 1, :nick => 2, :content => 3 }

  def initialize(parent, id = -1)
    #super(parent, id, "",
    #      Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE,
    #      Wx::TE_READONLY | Wx::TE_MULTILINE | Wx::TE_RICH | Wx::TE_RICH2
    #)
    super(parent, :style => Wx::SIMPLE_BORDER)
    self.use_horizontal_scroll_bar = true

    # Line wrapping
    self.wrap_mode = Wx::STC_WRAP_WORD
    self.wrap_start_indent = 24 # An estimate
    set_margin_width(1, 0)
    set_margins(5, 5)

    #Test
    #append_text("[04:22] <Sk-Marten>\terg lang bericht erg lang berichterg lang berichterg lang berichterg lang berichterg lang berichterg lang bericht")
    #append_text("\n[04:22] <basvd>\t\terg lang bericht erg lang berichterg lang berichterg lang berichterg lang berichterg lang berichterg lang bericht")
    #append_text("\n[04:22] <CountryBoy>\terg lang bericht erg lang berichterg lang berichterg lang berichterg lang berichterg lang berichterg lang bericht")
    self.read_only = true

    @nick_styles = Hash.new do |hash, key|
      id = STYLES[:nick] + (hash.length * 10)
      hash[key] = id

      r, g, b = rand(0x99), rand(0x99), rand(0x99) # TODO: Different colors
      style_set_foreground(id, Wx::Colour.new(r, g, b) || Wx::RED)
    end
  end

  def update(change = {})
    return if change[:messages].nil?

    self.read_only = false # Temporarily disable
    change[:messages].each do |msg|
      write_message(msg)
      line_scroll(0, wrap_count(get_line_count()) + 1)
    end
    self.read_only = true
  end

  def write_message(m)
      pos = get_length()
      time_range = [pos + 2, 5]
      text = "\n" + m.time.strftime("[%H:%M] ")
      text += "<" unless m.source_nick.nil?
      nick_range = [pos + text.length, m.source_nick.nil? ? 1 : m.source_nick.length]
      text += m.source_nick.nil? ? "#" : "#{m.source_nick}>"
      text += text.length > 16 ? "\t" : "\t\t"
      content_range = [pos + text.length, m.content.length]
      text += m.content
      append_text(text)

      style(:time, time_range)
      style(:nick, nick_range, m.source)
      style(:content, content_range)
  end

  def style(s, range, content = nil)
    id = STYLES[s]
    case s
    when :nick
      @nick_styles[content]
      id = @nick_styles[content]
    when :time
      style_set_foreground(id, Wx::Colour.new(0x66, 0x66, 0x66))
    when :content
      style_set_italic(id, true)
    end
    start_styling(range[0], 31)
    set_styling(range[1], id)
  end
end
