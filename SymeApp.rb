$LOAD_PATH.unshift File.dirname(__FILE__)

require "rubygems"

require "wx"
require "AppController"

SYME_NAME = "Syme IRC client"
SYME_VERSION = "0.1dev"
BASE_PATH = File.dirname(__FILE__)

class SymeApp < Wx::App
  def on_init
    @app = AppController.instance
  end
end

SymeApp.new.main_loop() unless defined? Ocra
