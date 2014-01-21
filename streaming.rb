require 'mycroft'
require './ui'

class Streaming < Mycroft::Client

  attr_accessor :verified

  def initialize
    @key = '/path/to/key'
    @cert = '/path/to/cert'
    @manifest = './app.json'
    @verified = false
  end

  def connect
    spawnUI(self);
  end
  
  def sendURL(url)
    
  end

  def on_data(parsed)
    # Your code here
  end

  def on_end
    # Your code here
  end
end

Mycroft.start(Streaming)
