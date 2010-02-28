require "wx"
require "gui/ChatControl"

class ChatWindow < Wx::SplitterWindow

  attr_reader :chan_topic, :chat_box

  def initialize(parent)
    super(parent, :style => Wx::SP_LIVE_UPDATE)

    # Left panel content
    @root_panel = Wx::Panel.new(self)
    # Chat window controls
    @chan_topic = Wx::TextCtrl.new(@root_panel, :style => Wx::TE_READONLY)
    def @chan_topic.update(change)
      if(!change[:topic].nil?)
        self.value = change[:topic]
        self.tool_tip = change[:topic]
      end
    end

    #expand_topic = Wx::BitmapButton.new(@root_panel, :bitmap => Wx::Bitmap.new("icons/control_270_small.png", Wx::BITMAP_TYPE_PNG))

    @chat_box = ChatControl.new(@root_panel)

    @nick_select = Wx::Choice.new(@root_panel)
    @nick_select.append("nick1")
    @nick_select.append("nick12")
    @nick_select.append("nick21")
    @nick_select.append("nick01")
    @nick_select.selection = 0

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

    @right_panel = Wx::Panel.new(self)
    @users_list = Wx::ListCtrl.new(@right_panel)
    users_text = Wx::StaticText.new(@right_panel,
                                    :label => "Users",
                                    :style => Wx::ALIGN_CENTER,
                                    :size => [-1, @chan_topic.best_size.height - 3])

    # Right panel layout
    right_size = Wx::BoxSizer.new(Wx::VERTICAL)
    right_size.add(users_text, 0, Wx::TOP | Wx::EXPAND, 3 + 5)
    right_size.add(@users_list, 1, (Wx::TOP | Wx::BOTTOM | Wx::RIGHT) | Wx::EXPAND, 5)

    @right_panel.sizer = right_size
    @right_panel.min_size = @right_panel.best_size

    @message_box.set_focus()

    set_minimum_pane_size([150, @right_panel.get_best_size().width].max)
    set_sash_gravity(1.0)
    split_vertically(@root_panel, @right_panel, -150)

    fit()
    set_min_size(get_best_size())
  end

end
