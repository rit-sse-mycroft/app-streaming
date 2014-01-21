require 'wx'
require 'uri'
require 'pathname'
require 'open-uri'
require './streaming'

class StreamURLMaker < Wx::Frame
  def initialize(title, thread)
    super(nil, -1, title, nil, Wx::Size.new(340,600), Wx::DEFAULT_FRAME_STYLE ^ Wx::RESIZE_BORDER)
    
    @mycroft = thread
    
    @sizer = Wx::GridBagSizer.new()
    
    @reslabel = Wx::StaticText.new(self, -1, "Resolution Scale")
    @resolution = Wx::SpinCtrl.new(self, -1, "", nil, nil, nil, 1, 100, 100)
    @perlabel = Wx::StaticText.new(self, -1, "%")
    @ressizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
    @ressizer.add(@reslabel, 0, Wx::ALIGN_CENTRE | Wx::ALL, 4)
    @ressizer.add(@resolution, 1, Wx::EXPAND)
    @ressizer.add(@perlabel, 0, Wx::ALIGN_CENTRE | Wx::ALL, 4)
    
    @filebutton = Wx::Button.new(self, -1, "File")
    evt_button(@filebutton) do #Get a file, make a vlc launch line form it, launch vlc, send our info to mycroft
      dialog = Wx::FileDialog.new(self, "Choose a file to stream")
      res = dialog.show_modal
      if (res==Wx::ID_OK)
        path = Pathname.new(dialog.get_directory+"\\\\"+dialog.get_filename).expand_path.to_s
        escaped = URI.escape(path, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        url = "file:///"+escaped
        
        launch = "vlc #{url} :sout=#transcode{vcodec=h264,scale=1,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:8080/mycroft.sdp} :sout-keep"
        pid = spawn(launch)
        sendIp
      end
    end
    
    @screenbutton = Wx::Button.new(self, -1, "Screen")
    evt_button(@screenbutton) do #Make vlc launch line, send info to mycroft
      url = "screen://"
      launch = "vlc #{url} :screen-fps=30 :screen-caching=100 :sout=#transcode{vcodec=h264,scale=1,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:8080/mycroft.sdp} :sout-keep"
      pid = spawn(launch)
      sendIp
    end
    
    @youtubebutton = Wx::Button.new(self, -1, "Youtube")
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
    
    set_sizer_and_fit @sizer
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
    Streaming.sendUrl(url)
  end
  
end


class MycroftStreamUI < Wx::App
  Mycroft.start(Streaming) # This is blocking. Why is this blocking.

  @frame = StreamURLMaker.new("Video Stream Launcher", thr)
end

app = MycroftStreamUI.new
app.main_loop