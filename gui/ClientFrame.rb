require "wx"
require "gui/ChatControl"
require "gui/ChatWindow"

class ClientFrame < Wx::Frame

  attr_reader :root_panel, :window_list

  def initialize(size = nil)
    super(
      nil,
      :title => SYME_NAME + " version " + SYME_VERSION,
      :pos => Wx::DEFAULT_POSITION,
      :size => [600, 400], #Wx::DEFAULT_SIZE,
      :style => Wx::DEFAULT_FRAME_STYLE
    )

    # Status bar
    @status_bar = create_status_bar(3, Wx::ST_SIZEGRIP)

    # Menu - Connection
    conn_menu = Wx::Menu.new()
    sl_item = conn_menu.append(:item => "Server list")

    conn_menu.append_separator()

    conn_item = conn_menu.append(:item => "Connect")
    disco_item = conn_menu.append(:item => "Disconnect")

    conn_menu.append()

    # Menu - Channel
    chan_menu = Wx::Menu.new()

    # Menu bar
    @menu_bar = Wx::MenuBar.new()
    @menu_bar.append(conn_menu, "Connection")
    @menu_bar.append(chan_menu, "Channel")

    self.menu_bar = @menu_bar

    @split_window = Wx::SplitterWindow.new(self, :style => Wx::SP_LIVE_UPDATE)
    @root_panel = ChatWindow.new(@split_window)
    @left_panel = Wx::Panel.new(@split_window)

    # Left panel content
    text_margin = 3 # margin for sidepanel labels
    @window_list = Wx::TreeCtrl.new(@left_panel, :style => Wx::TR_HAS_BUTTONS | Wx::TR_DEFAULT_STYLE)
    window_text = Wx::StaticText.new(@left_panel,
                                     :label => "Conversations",
                                     :style => Wx::ALIGN_CENTER,
                                     :size => [-1, @root_panel.chan_topic.best_size.height - text_margin])

    # Left panel layout
    left_size = Wx::BoxSizer.new(Wx::VERTICAL)
    left_size.add(window_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    left_size.add(@window_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::LEFT) | Wx::EXPAND, 5)

    @left_panel.sizer = left_size
    @left_panel.min_size = @left_panel.best_size

    # Split windows
    #@split_window.sash_gravity = 1.0
    @split_window.set_minimum_pane_size([150, @left_panel.get_best_size().width].max)
    @split_window.split_vertically(@left_panel, @root_panel, 150)

    @split_window.fit()
    @split_window.min_size = @split_window.best_size

    # Fit the frame
    fit()
    set_min_size(get_best_size())
    #maximize(true)
  end

  def add_chat(chan, parent = nil)
    if(parent.nil?)
      @window_list.add_root(chan.name)
    else
      p_id = nil
      @window_list.each do |id|
        p_id = id if parent == @window_list.get_item_text(id)
      end
      @window_list.ensure_visible(@window_list.append_item(p_id, chan.name)) unless p_id.nil?
    end
  end
end
