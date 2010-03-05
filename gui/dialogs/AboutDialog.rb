require "wx"
require "gui/LogoPanel"

class AboutDialog < Wx::Dialog

  def initialize(parent)
    super(parent,
          :title => "About Syme")

    about_panel = LogoPanel.new(self)
    about_panel.set_min_size([about_panel.logo.width, about_panel.logo.height])

    button_sz = create_button_sizer(Wx::OK)

    dialog_sz = Wx::BoxSizer.new(Wx::VERTICAL)

    dialog_sz.add(about_panel, 1, Wx::ALL | Wx::EXPAND, 5)
    dialog_sz.add(button_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    set_sizer_and_fit(dialog_sz)
  end
end
