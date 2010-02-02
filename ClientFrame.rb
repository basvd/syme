#!/usr/bin/env ruby

require "rubygems"
require "wx"
require "ChatControl"

class ClientFrame < Wx::Frame
  
  def initialize(size = nil)
    super(
      nil,
      :title => SYME_NAME + " version " + SYME_VERSION,
      :pos => Wx::DEFAULT_POSITION,
      :size => [600, 400], #Wx::DEFAULT_SIZE,
      :style => Wx::DEFAULT_FRAME_STYLE
    )
    
    @root_panel = Wx::Panel.new(self)
    
    # Status bar
    @status_bar = create_status_bar(3, Wx::ST_SIZEGRIP)
    
    # Menu - Connection
    conn_menu = Wx::Menu.new()
    sl_item = conn_menu.append(:item => "Server list")
    
    conn_menu.append_separator()
    
    conn_menu.append()
    
    # Menu - Channel
    chan_menu = Wx::Menu.new()
    
    # Menu bar
    @menu_bar = Wx::MenuBar.new()
    @menu_bar.append(conn_menu, "Connection")
    @menu_bar.append(chan_menu, "Channel")
    
    self.menu_bar = @menu_bar
    
    # Chat window controls
    @chan_topic = Wx::TextCtrl.new(@root_panel, :style => Wx::TE_READONLY)
    #expand_topic = Wx::BitmapButton.new(@root_panel, :bitmap => Wx::Bitmap.new("icons/control_270_small.png", Wx::BITMAP_TYPE_PNG))
    
    @chat_box = ChatControl.new(@root_panel)
    
    @nick_select = Wx::Choice.new(@root_panel)
    
    @message_box = Wx::TextCtrl.new(@root_panel, :style => Wx::TE_PROCESS_ENTER | Wx::TE_PROCESS_TAB)
    
    # Chat window layout sizer
    root_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    topic_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    topic_size.add(@chan_topic, 1)
    #topic_size.add(expand_topic, 0, Wx::LEFT | Wx::EXPAND, 5)
    root_siz.add(topic_size, 0, (Wx::ALL ) | Wx::EXPAND, 5)
    root_siz.add(@chat_box, 1, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)
    
    message_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    message_size.add(@nick_select, 0, Wx::RIGHT, 5)
    message_size.add(@message_box, 1)
    root_siz.add(message_size, 0, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)
    
    @root_panel.set_sizer_and_fit(root_siz)
    
    # Sashes
    left_sash = Wx::SashLayoutWindow.new(self, :style => 0)
    left_sash.set_default_size([150, self.get_size.y])
    left_sash.set_orientation(Wx::LAYOUT_VERTICAL)
    left_sash.set_alignment(Wx::LAYOUT_LEFT)
    left_sash.set_sash_visible(Wx::SASH_RIGHT, true)
    @left_panel = Wx::Panel.new(left_sash)
    
    right_sash = Wx::SashLayoutWindow.new(self, :style => 0)
    right_sash.set_default_size([150, self.get_size.y])
    right_sash.set_orientation(Wx::LAYOUT_VERTICAL)
    right_sash.set_alignment(Wx::LAYOUT_RIGHT)
    right_sash.set_sash_visible(Wx::SASH_LEFT, true)
    @right_panel = Wx::Panel.new(right_sash)
    
    # Left panel content
    text_margin = 3 # margin for sidepanel labels
    @window_list = Wx::ListCtrl.new(@left_panel)
    window_text = Wx::StaticText.new(@left_panel,
                                     :label => "Conversations",
                                     :style => Wx::ALIGN_CENTER,
                                     :size => [-1, @chan_topic.best_size.height - text_margin])
    
    # Left panel layout
    left_size = Wx::BoxSizer.new(Wx::VERTICAL)
    left_size.add(window_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    left_size.add(@window_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::LEFT) | Wx::EXPAND, 5)
    
    @left_panel.sizer = left_size
    @left_panel.min_size = @left_panel.best_size
    
    # Right panel content
    @users_list = Wx::ListCtrl.new(@right_panel)
    users_text = Wx::StaticText.new(@right_panel,
                                    :label => "Users",
                                    :style => Wx::ALIGN_CENTER,
                                    :size => [-1, @chan_topic.best_size.height - text_margin])
    
    # Right panel layout
    right_size = Wx::BoxSizer.new(Wx::VERTICAL)
    right_size.add(users_text, 0, Wx::TOP | Wx::EXPAND, text_margin + 5)
    right_size.add(@users_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::RIGHT) | Wx::EXPAND, 5)
    
    @right_panel.sizer = right_size
    @right_panel.min_size = @right_panel.best_size
    
    #Dummy content
    @chan_topic.value = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer quis orci metus."
    @chat_box.append_text("[00:11] <Lorem>\tipsum dolor sit amet, consasknlka kljasdl iksljdl aslksdlk asljd.\n")
    @chat_box.append_text("[11:22] <Lorem>\tipsum dolor sit amet, http://www.google.com/ consasknlka kljasdl iksljdl aslksdlk asljd.\n")
    @nick_select.append("nick1")
    @nick_select.append("nick12")
    @nick_select.append("nick21")
    @nick_select.append("nick01")
    @nick_select.selection = 0
    
    # Events
    evt_size() {|event| on_size(event)}
    evt_sash_dragged(left_sash.get_id) {|event| on_sash_drag(left_sash, event)}
    evt_sash_dragged(right_sash.get_id) {|event| on_sash_drag(right_sash, event)}
    
    #expanded = false
    #evt_button(expand_topic) do |event|
    #  toggle_mode = (Wx::TE_BESTWRAP | Wx::TE_MULTILINE)
    #  if(expanded)
    #    @chan_topic.set_window_style_flag(@chan_topic.get_window_style_flag() ^ toggle_mode)
    #    expanded = false
    #  else
    #    @chan_topic.set_window_style_flag(@chan_topic.get_window_style_flag() | toggle_mode)
    #    expanded = true
    #  end
    #end
    
    # Compute layout
    Wx::LayoutAlgorithm.new.layout_frame(self, @root_panel)
    
    fit()
    set_min_size(get_best_size())
    #maximize(true)
    
    @message_box.set_focus()
  end
  
  # Don't know why SashLayoutWindow doesn't handle this
  def on_sash_drag(sash, e)
    if(sash.orientation == Wx::LAYOUT_HORIZONTAL)
      size = [self.get_size.x, e.get_drag_rect.height()]
    elsif(sash.orientation == Wx::LAYOUT_VERTICAL)
      size = [e.get_drag_rect.width(), self.get_size.y]
    else
      e.veto()
      return
    end
    # Minimum size
    if(sash.alignment == Wx::LAYOUT_LEFT)
      m = @left_panel.get_best_size()
    elsif(sash.alignment == Wx::LAYOUT_RIGHT)
      m = @right_panel.get_best_size()
    end
    size = [[size[0], m.width].max, [size[1], m.height].max]
    sash.set_default_size(size)
    Wx::LayoutAlgorithm.new.layout_frame(self, @root_panel)
  end
  
  def on_size(e)
    e.skip()
    Wx::LayoutAlgorithm.new.layout_frame(self, @root_panel)
  end
end
