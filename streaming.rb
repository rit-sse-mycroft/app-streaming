require 'mycroft'

class Streaming < Mycroft::Client

  attr_accessor :verified

  def initialize
    @key = './streaming.key'
    @cert = './streaming.crt'
    @manifest = './app.json'
    @verified = false
    super
  end

  def connect
    up
  end
  
  def sendUrl(url)
    query("video", "stream", url)
  end

  def on_data(parsed)
    if parsed[:type] == 'MSG_QUERY_SUCCESS'
        puts "Stream started!"
    end
  end

  def on_end
    down
  end
end

