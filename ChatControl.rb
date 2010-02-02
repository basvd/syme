#!/usr/bin/env ruby

require "rubygems"
require "wx"

class ChatControl < Wx::TextCtrl
  def initialize(parent, id = -1)
    super(parent, id, "",
          Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE,
          Wx::TE_READONLY | Wx::TE_MULTILINE | Wx::TE_AUTO_URL | Wx::TE_RICH | Wx::TE_RICH2
    )
    
    # Basic character style
    chat_attr = Wx::TextAttr.new(Wx::BLACK)
    chat_attr.set_left_indent(0, 255)
    self.default_style = chat_attr
  end
end
