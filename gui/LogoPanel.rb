class LogoPanel < Wx::Panel

  attr_accessor :logo

  def initialize(parent, use_text = false, *args)
    super(parent, *args)

    if use_text
      @text = Wx::StaticText.new(self, :label => "Syme IRC client")
      evt_size :on_paint_text
    else
      logo_file = File.join("theme/", "syme-logo.png")
      @logo = Wx::Image.new(logo_file)
      evt_paint :on_paint_image
    end

    evt_size :on_size
  end

  def on_paint_text(event)
    x = (client_size.x - @text.size.width) / 2
    y = (client_size.y - @text.size.height) / 2
    @text.move(x, y)
  end

  def on_paint_image()
    paint_buffered do |dc|
      dc.clear()
      size = dc.size
      dc.set_brush(Wx::Brush.new(get_background_colour))
      dc.set_pen(Wx::Pen.new(get_background_colour))
      dc.draw_rectangle(0, 0, size.width, size.height)


      bm = @logo.to_bitmap()
      x = (client_size.x - bm.width) / 2
      y = (client_size.y - bm.height) / 2
      dc.draw_bitmap(bm, x, y, true)
    end
  end

  def on_size(event)
    refresh()
    event.skip()
  end
end
