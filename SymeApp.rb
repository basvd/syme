#!/usr/bin/env ruby

require "rubygems"
require "wx"
require "ClientFrame"

SYME_NAME = "Syme IRC client"
SYME_VERSION = "0.1dev"

class SymeApp < Wx::App
  def on_init
    ClientFrame.new.show()
  end
end

SymeApp.new.main_loop