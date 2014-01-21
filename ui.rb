require 'wx'
require 'uri'
require 'pathname'

class StreamURLMaker < Wx::Frame
  def initialize(title)
    super(nil, -1, title, nil, Wx::Size.new(340,600), Wx::DEFAULT_FRAME_STYLE)
    
    @sizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
    
    @filebutton = Wx::Button.new(self, -1, "File")
    evt_button(@filebutton) do #Get a file, make a vlc launch line form it, launch vlc, send our info to mycroft
      dialog = Wx::FileDialog.new(self, "Choose a file to stream")
      res = dialog.show_modal
      if (res==Wx::ID_OK)
        path = Pathname.new(dialog.get_filename).expand_path.to_s
        escaped = URI.escape(path, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        url = "file://"+escaped
        
        puts url
      end
    end
    
    @screenbutton = Wx::Button.new(self, -1, "Screen")
    evt_button(@screenbutton) do #Make vlc launch line, send info to mycroft
      url = "screen://"
      puts url
    end
    
    @youtubebutton = Wx::Button.new(self, -1, "Youtube")
    evt_button(@youtubebutton) do #Send url to mycroft
      dialog = Wx::TextEntryDialog.new(self, "Youtube video URL")
      res = dialog.show_modal
      if (res==Wx::ID_OK)
        url = dialog.get_value
        puts url
      end
    end
    
    @sizer.add(@filebutton, 1)
    @sizer.add(@screenbutton, 1)
    @sizer.add(@youtubebutton, 1)
    
    set_sizer_and_fit @sizer
    show
  end
end

class MycroftStreamUI < Wx::App
    def on_init()
        @frame = StreamURLMaker.new "Mycroft Video Stream Client"
    end
end

app = MycroftStreamUI.new
app.main_loop