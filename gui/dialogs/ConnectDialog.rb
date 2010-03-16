require "wx"

class ConnectDialog < Wx::Dialog

  def initialize(parent)
    super(parent,
          :title => "Connect to IRC")

    # Preset name
    @name_ctrl = Wx::TextCtrl.new(self, :value=> "New")
    name_label = Wx::StaticText.new(self, :label => "Name:", :style => Wx::ALIGN_RIGHT)

    # Preset name layout
    name_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    name_sz.add(name_label, 0, Wx::ALIGN_CENTER_VERTICAL)
    name_sz.add(@name_ctrl, 1, Wx::LEFT | Wx::EXPAND, 5)

    # Connection settings
    @host_ctrl = Wx::TextCtrl.new(self, :value=> "irc.freenode.net")
    host_label = Wx::StaticText.new(self, :label => "Host:", :style => Wx::ALIGN_RIGHT)
    @port_ctrl = Wx::TextCtrl.new(self, :value=> "6667")
    port_label = Wx::StaticText.new(self, :label => "Port:", :style => Wx::ALIGN_RIGHT)

    # Connection settings layout
    conn_group = Wx::StaticBoxSizer.new(Wx::VERTICAL, self, "Connection")

    conn_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    conn_sz.add(host_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALIGN_RIGHT)
    conn_sz.add(@host_ctrl, 1, Wx::LEFT | Wx::EXPAND, 5)
    conn_sz.add_spacer(10)
    conn_sz.add(port_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALIGN_RIGHT)
    conn_sz.add(@port_ctrl, 0, Wx::LEFT | Wx::EXPAND, 5)
    conn_group.add(conn_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    # Session settings
    @nick_ctrl = Wx::TextCtrl.new(self, :value=> "syme|irc")
    nick_label = Wx::StaticText.new(self, :label => "Nickname:", :style => Wx::ALIGN_RIGHT)
    @user_ctrl = Wx::TextCtrl.new(self, :value=> "syme")
    user_label = Wx::StaticText.new(self, :label => "Username:", :style => Wx::ALIGN_RIGHT)
    @chans_ctrl = Wx::TextCtrl.new(self, :value=> "##groept")
    chans_label = Wx::StaticText.new(self, :label => "Channel(s):", :style => Wx::ALIGN_RIGHT)

    # Session settings layout
    sess_group = Wx::StaticBoxSizer.new(Wx::VERTICAL, self, "Session")

    sess_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    sess_sz.add(nick_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALIGN_RIGHT)
    sess_sz.add(@nick_ctrl, 1, Wx::LEFT | Wx::EXPAND, 5)
    sess_sz.add_spacer(10)
    sess_sz.add(user_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALIGN_RIGHT)
    sess_sz.add(@user_ctrl, 1, Wx::LEFT | Wx::EXPAND, 5)
    sess_group.add(sess_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    sess_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    sess_sz.add(chans_label, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALIGN_RIGHT)
    sess_sz.add(@chans_ctrl, 1, Wx::LEFT | Wx::EXPAND, 5)
    sess_group.add(sess_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    # Settings layout
    settings_sz = Wx::BoxSizer.new(Wx::VERTICAL)
    settings_sz.add(name_sz, 0, Wx::ALL | Wx::EXPAND, 5)
    settings_sz.add(conn_group, 0, Wx::TOP | Wx::EXPAND, 5)
    settings_sz.add_spacer(10)
    settings_sz.add(sess_group, 0, Wx::EXPAND)

    # Server list
    @server_list = Wx::ListCtrl.new(self, :style => Wx::LC_LIST | Wx::LC_SINGLE_SEL)
    @server_list.insert_item(1, "Test")
    @server_list.insert_item(1, "Test 1")
    @server_list.insert_item(1, "Test 2")
    #server_label = Wx::StaticText.new(self, :label => "Servers", :style => Wx::ALIGN_CENTER)

    # Server list layout
    list_sz = Wx::BoxSizer.new(Wx::VERTICAL)
    #list_sz.add(server_label, 0, Wx::EXPAND)
    list_sz.add(@server_list, 1, Wx::TOP | Wx::EXPAND, 5)

    # Content layout
    content_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    content_sz.add(list_sz, 0, Wx::EXPAND)
    content_sz.add(settings_sz, 1, Wx::LEFT | Wx::EXPAND, 5)

    # Button bar
    @save_btn = Wx::Button.new(self, :label => "Save")
    @connect_btn = Wx::Button.new(self, Wx::ID_OK, :label => "Connect")
    @cancel_btn = Wx::Button.new(self, Wx::ID_CANCEL)

    button_sz = Wx::BoxSizer.new(Wx::HORIZONTAL)
    button_sz.add(@save_btn, 0, Wx::EXPAND)
    button_sz.add_stretch_spacer()
    button_sz.add(@connect_btn, 0, Wx::EXPAND)
    button_sz.add_spacer(10)
    button_sz.add(@cancel_btn, 0, Wx::EXPAND)

    # Dialog layout
    dialog_sz = Wx::BoxSizer.new(Wx::VERTICAL)
    dialog_sz.add(content_sz, 1, Wx::ALL | Wx::EXPAND, 5)
    dialog_sz.add(button_sz, 0, Wx::ALL | Wx::EXPAND, 5)

    set_sizer_and_fit(dialog_sz)
    centre_on_parent(Wx::BOTH)
    @connect_btn.set_focus()
  end

  def name
    return @name_ctrl.value
  end
  def host
    return @host_ctrl.value
  end
  def port
    return @port_ctrl.value
  end
  def nick
    return @nick_ctrl.value
  end
  def user
    return @user_ctrl.value
  end
  def channels
    return @chans_ctrl.value.split(",").map! do |c|
      c.strip
    end
  end

end
