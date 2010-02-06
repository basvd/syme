#!/usr/bin/env ruby

require "rubygems"

require "wx"
require "AppController"
require "gui/ClientFrame"

SYME_NAME = "Syme IRC client"
SYME_VERSION = "0.1dev"

class SymeApp < Wx::App
  def on_init
    @app = AppController.instance
    
    ClientFrame.new.show
  end
end

SymeApp.new.main_loop