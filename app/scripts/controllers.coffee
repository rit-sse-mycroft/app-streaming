Mycroft = require('mycroft')
exec = require('child_process').exec
os = require('os')

### Controllers ###

angular.module('app.controllers', [])

.controller('AppCtrl', [
  '$scope'
  '$location'
  '$resource'
  '$rootScope'

($scope, $location, $resource, $rootScope) ->
  
  $scope.vlcPath = (if (process.platform=='darwin') then '/Applications/VLC.app/Contents/MacOS/VLC' else 'vlc')
  $scope.webcam = (if (process.platform.indexOf('win')>=0) then 'dshow://' else 'qtcapture://')

  $scope.mycroft_host = 'localhost'
  $scope.mycroft_port = 1847
  $scope.mycroft_tls = false

  $scope.beginMycroftConnection = ->
    $scope.mycroft_host = document.getElementById('host').value #Temp hack
    $scope.connecting = true
    $scope.conn = new Mycroft(os.hostname()+'_Source', 'app.json', $scope.mycroft_host, $scope.mycroft_port);
    
    $scope.conn.on('CONNECTION_CLOSED', (data) -> 
      # ... Well.
      $scope.addAlert("Connection closed! New connection needs to be initiated.","warning")
    )
    $scope.conn.on('CONNECTION_ERROR', (data) -> 
      # ... Well.
      $scope.addAlert("Connection failed! Perhaps server is down, maybe?","warning")
      $scope.connecting = false;
      delete $scope.conn
    )
    $scope.conn.on('MANIFEST_ERROR', (err) ->
      $scope.addAlert("App manifest wasn't readable, connection couldn't be made.","warning")
      $scope.connecting = false;
      delete $scope.conn
    )
    $scope.conn.on('APP_MANIFEST_OK', (data) -> 
      $scope.connecting = false;
      $scope.conn.up()
      $scope.addAlert("Connected to Mycroft successfully! You may begin streaming at your leisure.")
    )
    $scope.conn.on('APP_MANIFEST_FAIL', (data) ->
      $scope.addAlert("App manifest message failed?")
    )
    $scope.conn.on('APP_DEPENDENCY', (data) ->
      console.log('Dependency management is a go!')
      for type, obj of data
        for name, status of obj
          $scope.targetStatus({name: name, type: type}, status)
    )
    
    try
      $scope.conn.connect()
      $scope.conn.sendManifest()
    catch
      $scope.addAlert('Connection failed. Is the server down?')
      
  $scope.targetStatus = (obj, status) ->
    console.log(status)
    if status=='down'
      for ind, existing of $scope.targets
        if existing.name==obj.name
          $scope.targets.splice(ind, 1)
          return
    else
      for ind, existing of $scope.targets
        if existing.name==obj.name
          obj.selected = existing.selected
          $scope.targets[ind] = obj
          return
      $scope.targets.push(obj)
    console.log($scope.targets)
    
    
  # Uses the url to determine if the selected
  # menu item should have the class active.
  $scope.$location = $location
  $scope.$watch('$location.path()', (path) ->
    $scope.activeNavId = path || '/'
  )

  # getClass compares the current url with the id.
  # If the current url starts with the id it returns 'active'
  # otherwise it will return '' an empty string. E.g.
  #
  #   # current url = '/products/1'
  #   getClass('/products') # returns 'active'
  #   getClass('/orders') # returns ''
  #
  $scope.getClass = (id) ->
    if (id && $scope.activeNavId.substring(0, id.length) == id)
      return 'active'
    else
      return ''
    
    
  $scope.targets = []
  
  $scope.filterTypes = () ->
    types = []
    for ind,v of $scope.targets
      if (v.type not in types) and v.selected
        types.push(v.type)
        
    console.log(types)
    types
    
  $scope.getIp = (func) ->
    req = new XMLHttpRequest()
    req.onload = () ->
      func(this.responseText)
    req.open('get', 'http://whatismyip.akamai.com', false)
    req.send();
  
  $scope.startStream = ->
    targets = []
    for item in $scope.targets
      if item.selected 
        targets.push(item.name)
    if $scope.conn
      ctrlr = angular.element($('#'+$scope.activeNavId.substring(1))).scope()
      console.log(ctrlr)
      $scope.getIp( (ip) ->
        to_play = ctrlr.streamData(ip, (data) ->
          for type in $scope.filterTypes()
            console.log('Sending a thingy query!')
            $scope.conn.query(type, 'video_stream', data, targets)
        )
        old = $('#vlcplayer')
        new_player = old.clone()
        new_player.attr('src', to_play)
        new_player.insertBefore(old)
        old.remove()
      )
    else
      $scope.addAlert("Connection not established, can't start a video.", "warning")
        
  $scope.haltStream = ->
    targets = []
    for item in $scope.targets
      if item.selected 
        targets.push(item.name)
    if $scope.conn
      for type in $scope.filterTypes()
        $scope.conn.query(type, 'halt', {}, targets)
    else
      $scope.addAlert("Connection not established, can't halt a video.", "warning")
        
  $scope.addAlert = (msg, type) ->
      if not $scope.alerts
        $scope.alerts = []
      $scope.alerts.push
        msg: msg
        type: type
        
  $scope.closeAlert = (obj) ->
    $scope.alerts.splice(obj, 1);
      
    
])

.controller('connectionObj', [
  '$scope'
  
($scope) ->
  $scope
])

.controller('screen', [
  '$scope'

($scope) ->
  $scope.scale = 100
  
  $scope.streamData = (ip, block) ->
    scale = (($scope.scale/100).toFixed(2))
    port = Math.floor(Math.random() * (30000 - 3000 + 1) + 3000);
    cmd = _.template($scope.vlcPath+" screen:// --screen-fps=30.000000 --sout=\"#duplicate{dst=\'transcode{vcodec=h264,fps=30,scale=<%= scale %>,acodec=mp3,ab=128,channels=2,samplerate=8000}:rtp{sdp=rtsp://:"+port+"/mycroft.sdp}\', dst=display}\"")
    compiled = cmd(
      scale: scale
    )
    exec(compiled, (err, stdout, stderr) ->
      console.log('Command executed!');
      console.log('VLC stdout: ' + stdout);
      console.log('VLC stderr: ' + stderr);
    )
    data = url: 'rtsp://'+ip+':'+port+'/mycroft.sdp'
    block(data)
    data
])

.controller('webcam', [
  '$scope'

($scope) ->
  $scope.scale = 100
  
  $scope.streamData = (ip, block) ->
    scale = (($scope.scale/100).toFixed(2))
    port = Math.floor(Math.random() * (30000 - 3000 + 1) + 3000);
    cmd = _.template($scope.vlcPath+" "+$scope.webcam+" --sout=\"#dusplicate{dst=\'transcode{vcodec=h264,scale=<%= scale %>,acodec=mp3,ab=128,channels=2,fps=3-}:rtp{sdp=rtsp://:"+port+"/mycroft.sdp}\', dst=display}\"")
    compiled = cmd(
      scale: scale
    )
    exec(compiled, (err, stdout, stderr) ->
      console.log('Command executed!');
      console.log('VLC stdout: ' + stdout);
      console.log('VLC stderr: ' + stderr);
    )
    data = url: 'rtsp://'+ip+':'+port+'/mycroft.sdp'
    block(data)
    data
])

.controller('youtube', [
  '$scope'

($scope) ->
  $scope.streamData = (ip, block)->
    block(url: $scope.url)
    $scope.url
])

.controller('file', [
  '$scope'

($scope) ->
        
  $scope.scale = 100
  
  $scope.streamData = (ip, block) ->
    filelist = []
    for elem in document.getElementById('fileDialog').files
      filelist.push(encodeURIComponent(elem.path))
    files = filelist.join('+')
    filepaths = "file:///"+files
    scale = +(($scope.scale/100).toFixed(2))
    port = Math.floor(Math.random() * (30000 - 3000 + 1) + 3000);
    cmd = _.template($scope.vlcPath+" -vvv <%= url %> --sout=\"#duplicate{dst=\'transcode{venc=x264,vcodec=h264,threads=8,bframes=0,scale=<%= scale %>,acodec=mpga,ab=128,channels=2,samplerate=44100,acodec=mp3,scodec=t140,soverlay,audio-sync=1}:rtp{sdp=rtsp://:"+port+"/mycroft.sdp}\', dst=display}\"")
    compiled = cmd(
      scale: scale
      url: filepaths
    )
    console.log(compiled)
    exec(compiled, (err, stdout, stderr) ->
      console.log('Command executed!');
      console.log('VLC stdout: ' + stdout);
      console.log('VLC stderr: ' + stderr);
    )
    data = url: 'rtsp://'+ip+':'+port+'/mycroft.sdp'
    block(data)
    data
        
  holder = document.getElementById('fileDialog')
  holder.ondragover = ->
    @className = 'hover'
    false
    
  holder.ondragend = ->
    @className = ''
    false
    
  holder.ondrop = (e) ->
    e.preventDefault();
    holder.files = e.dataTransfer.files
    false
])

window.ondragover = (e) -> 
  e.preventDefault()
  false

window.ondrop = (e) ->
  e.preventDefault()
  false