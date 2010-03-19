require "wx"
require "gui/ChatControl"
require "gui/dialogs/AboutDialog"

class ClientFrame < Wx::Frame

  attr_reader :chat_box, :current_chat, :topic_text, :window_list

  def initialize(app)
    super(
      nil,
      :title => SYME_NAME + " version " + SYME_VERSION,
      :pos => Wx::DEFAULT_POSITION,
      :size => [600, 400], #Wx::DEFAULT_SIZE,
      :style => Wx::DEFAULT_FRAME_STYLE ^ Wx::WANTS_CHARS
    )

    @app = app

    # Status bar
    @status_bar = create_status_bar(3, Wx::ST_SIZEGRIP)

    # Menu - Connection
    conn_menu = Wx::Menu.new()
    sl_item = conn_menu.append(-1, "Server list")

    conn_menu.append_separator()

    conn_item = conn_menu.append(-1, "Connect")
    disco_item = conn_menu.append(-1, "Disconnect")

    # Menu - Channel
    chan_menu = Wx::Menu.new()

    # Menu - Help
    help_menu = Wx::Menu.new()
    about_item = help_menu.append(Wx::ID_ABOUT, "About")

    evt_menu about_item do |event|
      AboutDialog.new(self).show()
    end

    # Menu bar
    @menu_bar = Wx::MenuBar.new()
    @menu_bar.append(conn_menu, "Connection")
    @menu_bar.append(chan_menu, "Channel")
    @menu_bar.append(help_menu, "Help")

    set_menu_bar(@menu_bar)

    # Frame content
    text_margin = 3 # margin for sidepanel labels

    # Left side splitter window
    @split_window = Wx::SplitterWindow.new(self, :style => Wx::SP_LIVE_UPDATE)
    @left_panel = Wx::Panel.new(@split_window)

    # Right side splitter window
    @chat_window = Wx::SplitterWindow.new(@split_window, :style => Wx::SP_LIVE_UPDATE)
    @chat_panel = Wx::Panel.new(@chat_window)
    @right_panel = Wx::Panel.new(@chat_window)

    # Chat panel content
    @chat_controls = Hash.new(LogoPanel.new(@chat_panel, false)) # use logo by default

    @topic_text = Wx::TextCtrl.new(@chat_panel, :style => Wx::TE_READONLY)
    def @topic_text.update(subject, change = {})
      if(!change[:topic].nil?)
        self.value = change[:topic]
        self.tool_tip = change[:topic]
      end
    end

    #expand_topic = Wx::BitmapButton.new(@chat_panel, :bitmap => Wx::Bitmap.new("icons/control_270_small.png", Wx::BITMAP_TYPE_PNG))

    @chat_box = @chat_controls[nil]

    @nick_select = Wx::Choice.new(@chat_panel)
    @nick_select.append("nick1")
    @nick_select.append("nick12")
    @nick_select.append("nick21")
    @nick_select.append("nick01")
    @nick_select.selection = 0

    @message_box = Wx::TextCtrl.new(@chat_panel, :style => Wx::TE_PROCESS_ENTER | Wx::TE_PROCESS_TAB)

    # Hide all chat panel controls
    @topic_text.show(false)
    @nick_select.show(false)
    @message_box.show(false)

    # Chat panel layout
    @chat_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    topic_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    topic_size.add(@topic_text, 1)
    #topic_size.add(expand_topic, 0, Wx::LEFT | Wx::EXPAND, 5)
    @chat_siz.add(topic_size, 0, Wx::ALL | Wx::EXPAND, 5)
    @chat_siz.add(@chat_box, 1, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)

    message_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    message_size.add(@nick_select, 0, Wx::RIGHT, 5)
    message_size.add(@message_box, 1)
    @chat_siz.add(message_size, 0, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)

    @chat_panel.set_sizer_and_fit(@chat_siz)

    # Right panel content
    @users_list = Wx::ListCtrl.new(@right_panel)
    def @users_list.update(subject, change ={})

    end
    users_text = Wx::StaticText.new(@right_panel,
                 :label => "Users",
                 :style => Wx::ALIGN_CENTER,
                 :size => [-1, @topic_text.best_size.height - text_margin])

    # Right panel layout
    right_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    right_siz.add(users_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    right_siz.add(@users_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::RIGHT) | Wx::EXPAND, 5)

    @right_panel.sizer = right_siz
    @right_panel.min_size = @right_panel.best_size

    @message_box.set_focus()



    # Left panel content
    @window_list = Wx::TreeCtrl.new(@left_panel,
                   :style => Wx::TR_HAS_BUTTONS | Wx::TR_DEFAULT_STYLE | Wx::TR_HIDE_ROOT | Wx::TR_NO_LINES)
    @window_list.add_root("Servers")
    window_text = Wx::StaticText.new(@left_panel,
                  :label => "Conversations",
                  :style => Wx::ALIGN_CENTER,
                  :size => [-1, @topic_text.best_size.height - text_margin])

    # Left panel layout
    left_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    left_siz.add(window_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    left_siz.add(@window_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::LEFT) | Wx::EXPAND, 5)

    @left_panel.sizer = left_siz
    @left_panel.min_size = @left_panel.best_size

    # Split windows
    @split_window.set_minimum_pane_size([150, @left_panel.get_best_size().width].max)
    @split_window.split_vertically(@left_panel, @chat_window, 150)

    @split_window.fit()
    @split_window.min_size = @split_window.best_size

    @chat_window.set_minimum_pane_size([150, @right_panel.best_size.width].max)
    @chat_window.set_sash_gravity(1.0)
    @chat_window.split_vertically(@chat_panel, @right_panel, -150)
    @chat_window.unsplit(@right_panel)

    @chat_window.fit()
    @chat_window.min_size = @chat_window.best_size

    # Fit the frame
    set_min_size([600, 500])
    fit()
    #maximize(true)

    # Events
    evt_menu sl_item do |event|
      @app.on_menu_conn(event)
    end
    evt_text_enter @message_box do |event|
      @app.on_chat_command(event)
      @message_box.value = ""
    end
    evt_close do |event|
      @app.on_close(event)
    end
    evt_tree_sel_changed @window_list, :on_chat_change
    @window_list.evt_set_focus do |event|
      @message_box.set_focus()
    end
  end

  def on_chat_change(event)
    new_chat = @window_list.get_item_data(event.get_item())

    if new_chat.nil?
      event.veto()
    else
      freeze()

      # Update topic_text + observer
      @current_chat.delete_observer(@topic_text) unless @current_chat.nil?

      if new_chat.respond_to? :topic
        @topic_text.value = new_chat.topic unless new_chat.topic.nil?
      else
        @topic_text.value = new_chat.name unless new_chat.name.nil?
      end
      new_chat.add_observer(@topic_text)

      # Update users_list + observer
      if new_chat.respond_to? :users
        @current_chat.delete_observer(@users_list)
        new_chat.add_observer(@users_list)
        @chat_window.split_vertically(@chat_panel, @right_panel, @last_sash_pos || -150) unless @chat_window.is_split()
      elsif @chat_window.is_split()
        @current_chat.delete_observer(@users_list)
        @last_sash_pos = @chat_window.get_sash_position()
        @chat_window.unsplit(@right_panel)
      end

      # Replace chat_box (keep observer)
      if @chat_box.is_a? LogoPanel
        @topic_text.show()
        @nick_select.show()
        @message_box.show()
      end

      ctrl = @chat_controls[new_chat]
      @chat_siz.replace(@chat_box, ctrl)
      @chat_box.show(false)
      ctrl.show(true)
      @chat_box = ctrl
      @current_chat = new_chat

      @chat_panel.layout()
      @message_box.set_focus()
      thaw()
    end
  end

  def update(subject = nil, change = {})
    # WxRuby update instead of Observer update...
    return if change[:add_message].nil? && subject == nil

    if subject.is_a? ConnectionList
      conn = change[:add_connection]
      unless conn.nil?
        add_chat(conn.chat)
        conn.add_observer(self)
      end
    elsif subject.is_a? Connection
      add_chat(change[:add_channel], subject.chat) if change.has_key? :add_channel
      add_chat(change[:add_private], subject.chat) if change.has_key? :add_private
    end
  end

  private
  def add_chat(chat, parent = nil)
    # Create chat control
    unless @chat_controls.has_key? chat
      freeze()
      ctrl = ChatControl.new(@chat_panel)
      ctrl.show(false)
      thaw()

      @chat_controls[chat] = ctrl
      chat.add_observer(ctrl)
    end

    # Adding a subchat?
    if parent.nil?
      list_id = @window_list.append_item(@window_list.root_item, chat.name)
      @window_list.set_item_has_children(list_id, true)
    else
      p_id = 0
      @window_list.each do |id|
        p_id = id if parent == @window_list.get_item_data(id)
      end
      list_id = @window_list.append_item(p_id, chat.name)
    end
    @window_list.set_item_data(list_id, chat)

    @window_list.ensure_visible(list_id)
    @window_list.select_item(list_id)
  end

  def remove_chat(chat)
    ctrl = @chat_controls.delete(chat)
    chat.delete_observer(ctrl)
    # Destroy chat control
    ctrl.destroy() unless ctrl.nil?
  end
end
