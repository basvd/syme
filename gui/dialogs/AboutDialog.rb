require "wx"
require "gui/LogoPanel"

class AboutDialog < Wx::Dialog

  def initialize(parent)
    super(parent,
          :title => "About Syme")

    about_panel = LogoPanel.new(self, false, :style => Wx::SIMPLE_BORDER)
    about_panel.background_colour = Wx::WHITE
    about_panel.set_min_size([about_panel.logo.width, about_panel.logo.height])

    # Text items
    text = [
    [Wx::StaticText.new(self, :label => "Version:", :style => Wx::ALIGN_RIGHT),
     Wx::StaticText.new(self, :label => "0.1dev", :style => Wx::ALIGN_LEFT)],
    [Wx::StaticText.new(self, :label => "Homepage:", :style => Wx::ALIGN_RIGHT),
     Wx::HyperlinkCtrl.new(self, :url => "http://github.com/basvd/syme/", :label => "http://github.com/basvd/syme/", :style => Wx::HL_ALIGN_LEFT | Wx::HL_CONTEXTMENU | Wx::NO_BORDER)],
    [Wx::StaticText.new(self, :label => "License:", :style => Wx::ALIGN_RIGHT),
     Wx::StaticText.new(self,
     :label =>
"This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.",
     :style => Wx::ALIGN_LEFT)]
    ]

    text_sz = Wx::FlexGridSizer.new(text.length, 2, 5, 5)
    text_sz.add_growable_col(0, 1)
    text_sz.add_growable_col(1, 3)
    text.each do |left, right|
      text_sz.add(left, 0, Wx::EXPAND)
      text_sz.add(right, 1, Wx::EXPAND)
    end


    button_sz = create_button_sizer(Wx::OK)

    dialog_sz = Wx::BoxSizer.new(Wx::VERTICAL)

    dialog_sz.add(about_panel, 0, Wx::ALL | Wx::EXPAND, 5)
    dialog_sz.add(text_sz, 1, Wx::ALL | Wx::EXPAND, 5)
    dialog_sz.add(button_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    set_sizer_and_fit(dialog_sz)
  end
end
