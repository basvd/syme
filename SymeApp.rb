require "rubygems"

require "wx"
require "AppController"

SYME_NAME = "Syme IRC client"
SYME_VERSION = "0.1dev"

class SymeApp < Wx::App
  def on_init
    @app = AppController.instance
  end
end

SymeApp.new.main_loop