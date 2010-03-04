require "wx"
require "gui/ChatControl"
require "gui/ChatWindow"

class ClientFrame < Wx::Frame

  attr_reader :chat_window, :window_list

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
    @left_panel = Wx::Panel.new(@split_window)

    @chat_window = ChatWindow.new(@split_window)

    # Left panel content
    text_margin = 3 # margin for sidepanel labels
    @window_list = Wx::TreeCtrl.new(@left_panel, :style => Wx::TR_HAS_BUTTONS | Wx::TR_DEFAULT_STYLE)
    window_text = Wx::StaticText.new(@left_panel,
                                     :label => "Conversations",
                                     :style => Wx::ALIGN_CENTER,
                                     :size => [-1, @chat_window.topic_text.best_size.height - text_margin])

    # Left panel layout
    left_size = Wx::BoxSizer.new(Wx::VERTICAL)
    left_size.add(window_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    left_size.add(@window_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::LEFT) | Wx::EXPAND, 5)

    @left_panel.sizer = left_size
    @left_panel.min_size = @left_panel.best_size

    # Split windows
    #@split_window.sash_gravity = 1.0
    @split_window.set_minimum_pane_size([150, @left_panel.get_best_size().width].max)
    @split_window.split_vertically(@left_panel, @chat_window, 150)

    @split_window.fit()
    @split_window.min_size = @split_window.best_size

    # Events
    evt_tree_sel_changed(@window_list, :on_chat_change)

    # Fit the frame
    fit()
    set_min_size(get_best_size())
    #maximize(true)
  end

  def on_chat_change(event)
    # TODO: Do not use multiple chatwindows, pass chat to existing one instead and let it deal with it.
    new_chat = @window_list.get_item_data(event.get_item())

    @chat_window.current_chat = new_chat
  end

  def update(subject = nil, change = {})
    # WxRuby update instead of Observer update...
    return if change[:messages].nil? && subject == nil

    if subject.is_a? ConnectionList
      conn = change[:add_connection]
      unless conn.nil?
        add_chat(conn.chat)
        conn.add_observer(self)
      end
    elsif subject.is_a? Connection
      add_chat(change[:add_channel], subject.chat) unless change[:add_channel].nil?
      add_chat(change[:add_private], subject.chat) unless change[:add_private].nil?
    end
  end

  private
  def add_chat(chat, parent = nil)
    @chat_window.add_chat(chat)

    # Adding a subchat?
    if parent.nil?
      list_id = @window_list.add_root(chat.name)
      @window_list.set_item_has_children(list_id, true)
    else
      p_id = 0
      @window_list.each do |id|
        p_id = id if parent == @window_list.get_item_data(id)
      end
      list_id = @window_list.append_item(p_id, chat.name)
    end
    @window_list.ensure_visible(list_id)
    @window_list.set_item_data(list_id, chat)
  end
end
