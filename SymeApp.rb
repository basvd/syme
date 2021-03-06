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
  def on_exit
    @app.on_exit
  end
end

if __FILE__ == $0
  SymeApp.new.main_loop() unless defined? Ocra
end
