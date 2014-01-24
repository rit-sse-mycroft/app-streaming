require 'mycroft'

class Streaming < Mycroft::Client

  attr_accessor :verified

  def initialize(ui)
    @key = './streaming.key'
    @cert = './streaming.crt'
    @manifest = './app.json'
    @verified = false
    @players = {}
    @ui = ui
    @threaded = true
    super('localhost', 1847)
  end

  def connect

  end
  
  def sendUrl(url, dest = nil)
    query("video", "video_stream", {url: url}, 30, dest)
  end
  
  def sendHalt(dests = [])
    query("video", "halt", {}, 30, dests)
  end

  def on_data(parsed)
    if parsed[:type] == 'APP_MANIFEST_OK'
      up
    elsif parsed[:type] == 'MSG_QUERY_SUCCESS'
      puts "Stream started!"
    elsif parsed[:type] == 'APP_DEPENDENCY'
      puts "Updating player list"
      @players = parsed[:data]['video']
      puts @players
      parsed[:data]['speakers'].each do |key, val|
        @players[key] = val
      end
      @ui.players_changed(@players)
    end
  end

  def on_end
  end
end

