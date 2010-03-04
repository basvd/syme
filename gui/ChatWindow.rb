require "wx"
require "gui/ChatControl"

class ChatWindow < Wx::SplitterWindow

  attr_reader :chat_box, :current_chat, :topic_text

  def initialize(parent)
    super(parent, :style => Wx::SP_LIVE_UPDATE)

    # Left panel content
    @root_panel = Wx::Panel.new(self)
    # Chat window controls
    @topic_text = Wx::TextCtrl.new(@root_panel, :style => Wx::TE_READONLY)
    def @topic_text.update(subject, change = {})
      if(!change[:topic].nil?)
        self.value = change[:topic]
        self.tool_tip = change[:topic]
      end
    end

    #expand_topic = Wx::BitmapButton.new(@root_panel, :bitmap => Wx::Bitmap.new("icons/control_270_small.png", Wx::BITMAP_TYPE_PNG))

    @chat_controls = {}
    @chat_box = Wx::Panel.new(@root_panel)#ChatControl.new(@root_panel)

    @nick_select = Wx::Choice.new(@root_panel)
    @nick_select.append("nick1")
    @nick_select.append("nick12")
    @nick_select.append("nick21")
    @nick_select.append("nick01")
    @nick_select.selection = 0

    @message_box = Wx::TextCtrl.new(@root_panel, :style => Wx::TE_PROCESS_ENTER | Wx::TE_PROCESS_TAB)

    # Chat window layout sizer
    @root_siz = Wx::BoxSizer.new(Wx::VERTICAL)
    topic_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    topic_size.add(@topic_text, 1)
    #topic_size.add(expand_topic, 0, Wx::LEFT | Wx::EXPAND, 5)
    @root_siz.add(topic_size, 0, Wx::ALL | Wx::EXPAND, 5)
    @root_siz.add(@chat_box, 1, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)

    message_size = Wx::BoxSizer.new(Wx::HORIZONTAL)
    message_size.add(@nick_select, 0, Wx::RIGHT, 5)
    message_size.add(@message_box, 1)
    @root_siz.add(message_size, 0, (Wx::ALL ^ Wx::TOP) | Wx::EXPAND, 5)

    @root_panel.set_sizer_and_fit(@root_siz)

    @right_panel = Wx::Panel.new(self)
    @users_list = Wx::ListCtrl.new(@right_panel)
    users_text = Wx::StaticText.new(@right_panel,
                                    :label => "Users",
                                    :style => Wx::ALIGN_CENTER,
                                    :size => [-1, @topic_text.best_size.height - 3])

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
    unsplit(@right_panel)

    fit()
    set_min_size(get_best_size())
  end

  def current_chat=(chat)
    freeze()

    # Update topic_text + observer
    @current_chat.delete_observer(@topic_text) unless @current_chat.nil?
    @topic_text.value = (chat.respond_to? :topic) ? chat.topic : ""
    chat.add_observer(@topic_text)

    # Update users_list + observer
    # TODO: Update observable for users_list
    if chat.respond_to? :users
      split_vertically(@root_panel, @right_panel, @last_sash_pos || -150) unless is_split()
    elsif is_split()
      @last_sash_pos = get_sash_position()
      unsplit(@right_panel)
    end

    # Replace chat_window (keep observer)
    ctrl = @chat_controls[chat]
    @root_siz.replace(@chat_box, ctrl)
    @chat_box.show(false)
    ctrl.show(true)
    @chat_box = ctrl

    @root_panel.layout()
    thaw()
  end

  def add_chat(chat)
    # Create chat control
    if @chat_controls[chat].nil?
      freeze()
      ctrl = ChatControl.new(@root_panel)
      ctrl.show(false)
      thaw()

      @chat_controls[chat] = ctrl
      chat.add_observer(ctrl)
    end
  end

  def remove_chat(chat)
    ctrl = @chat_controls.delete(chat)
    chat.delete_observer(ctrl)
    # Destroy chat control
    ctrl.destroy() unless ctrl.nil?
  end
end
