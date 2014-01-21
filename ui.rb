require 'wx'
require 'uri'
require 'pathname'
require 'open-uri'
require './streaming'

class StreamURLMaker < Wx::Frame
  def initialize(title)
    super(nil, -1, title, nil, Wx::Size.new(340,600), Wx::DEFAULT_FRAME_STYLE ^ Wx::RESIZE_BORDER)
    @bg = Wx::Panel.new(self)
    
    @sizer = Wx::GridBagSizer.new(4, 0)
    
    @reslabel = Wx::StaticText.new(@bg, -1, "Resolution Scale")
    @resolution = Wx::SpinCtrl.new(@bg, -1, "", nil, nil, nil, 1, 100, 100)
    @perlabel = Wx::StaticText.new(@bg, -1, "%")
    @ressizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
    @ressizer.add(@reslabel, 0, Wx::ALIGN_CENTRE | Wx::ALL, 4)
    @ressizer.add(@resolution, 1, Wx::EXPAND)
    @ressizer.add(@perlabel, 0, Wx::ALIGN_CENTRE | Wx::ALL, 4)
    
    @filebutton = Wx::Button.new(@bg, -1, "File")
    evt_button(@filebutton) do #Get a file, make a vlc launch line form it, launch vlc, send our info to mycroft
      dialog = Wx::FileDialog.new(self, "Choose a file to stream")
      res = dialog.show_modal
      if (res==Wx::ID_OK)
        path = Pathname.new(dialog.get_directory+"\\\\"+dialog.get_filename).expand_path.to_s
        escaped = URI.escape(path, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        url = "file:///"+escaped
        res = @resolution.get_value
        frac = "%0.2f" % (res.to_i/100)
        
        launch = "vlc #{url} :sout=#transcode{vcodec=h264,scale=#{frac},acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:8080/mycroft.sdp} :sout-keep"
        pid = spawn(launch)
        sendIp
      end
    end
    
    @screenbutton = Wx::Button.new(@bg, -1, "Screen")
    evt_button(@screenbutton) do #Make vlc launch line, send info to mycroft
      url = "screen://"
      res = @resolution.get_value
      frac = "%0.2f" % (res.to_i/100)
    
    launch = "vlc #{url} :screen-fps=30 :screen-caching=100 :sout=#transcode{vcodec=h264,scale=#{frac},acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:8080/mycroft.sdp} :sout-keep"
      pid = spawn(launch)
      sendIp
    end
    
    @youtubebutton = Wx::Button.new(@bg, -1, "Youtube")
    evt_button(@youtubebutton) do #Send url to mycroft
      dialog = Wx::TextEntryDialog.new(self, "Youtube video URL")
      res = dialog.show_modal
      if (res==Wx::ID_OK)
        url = dialog.get_value
        sendUrl(url)
      end
    end
    
    @sizer.add(@filebutton, Wx::GBPosition.new)
    @sizer.add(@screenbutton, Wx::GBPosition.new(0,1))
    @sizer.add(@youtubebutton, Wx::GBPosition.new(0,2))
    
    @sizer.add(@ressizer, Wx::GBPosition.new(1,0), Wx::GBSpan.new(1, 3))
    @checksizer = Wx::StaticBoxSizer.new(Wx::VERTICAL, @bg, "Target Players")
    
    
    @sizer.add(@checksizer, Wx::GBPosition.new(2,0), Wx::GBSpan.new(1, 3), Wx::EXPAND)
    
    @bg.set_sizer_and_fit @sizer
    
    bgsizer = Wx::BoxSizer.new(Wx::VERTICAL)
    bgsizer.add(@sizer)
    
    set_sizer_and_fit bgsizer
    
    show
  end
  
  def sendIp
    ipdata = open('http://whatismyip.akamai.com').read
    if (ipdata)
      oururl = "rtsp://"+ipdata.to_s+":8080/mycroft.sdp"
      sendUrl(oururl)
    end
  end

  def sendUrl(url)
    dest = []
    @checksizer.get_children.each do |obj|
      if (obj.is_a? Wx::CheckBox) and obj.is_checked
        dest.add(obj.get_label_text)
      end
    end
    
    if (@client)
      @client.sendUrl(url, dest)
    else
      puts "Tried to send a URL before client was connected"
    end
  end
  
  def update_players(players)
    @checksizer.get_children.each do |obj|
      if obj.is_a? Wx::CheckBox
        obj.remove
      end
    end
    
    players.each do |key, value|
      if (value!='down')
        box = Wx::CheckBox.new(@bg, -1, key.to_s)
        box.set_value true
        @checksizer.add(box, 1, Wx::EXPAND | Wx::CENTER)
      end
    end
    
    @sizer.fit self
    @sizer.fit @bg
  end
  
end


class MycroftStreamUI < Wx::App

  def on_init
    @frame = StreamURLMaker.new("Video Stream Launcher")
    #Thread.abort_on_exception = true #Aborts program, unfortunately
    begin
      Thread.new do
        cli = Streaming.new(self)
        @frame.client = cli
      end
    
    rescue Exception => e
      puts "Failed to connect - maintaining UI"
      puts "Error message:"
      puts e
    end
  end
  
  def players_changed(players)
    @frame.update_players(players)
  end
end

app = MycroftStreamUI.new
app.main_loop