`
var tls = require('tls');
var net = require('net');
//var uuid = require('uuid');
var node_crypto = require('crypto');
var rby = function(bytes) {
  return node_crypto.randomBytes(bytes).toString('hex');
}
var uuid = {v4: function() {
    return (rby(4)+'-'+rby(2)+'-4'+rby(2).slice(1)+'-a'+rby(2).slice(1)+'-'+rby(6)) //This is a terrible hack
}};
var fs = require('fs');
var sys = require('sys')
var exec = require('child_process').exec;
var http = require('http')
var MYCROFT_PORT = 1847;

var Mycroft = function(manifest, host, port) {

  this.status = 'down';
  this.host = host || 'localhost';
  this.manifest_loc = manifest || 'app.json';
  this.port = port || MYCROFT_PORT;
  this.handlers = {};
  
  this._unconsumed = '';

  // Parses a received message and returns an array of commands as
  // an Object containing type:String and data:Object.
  // There is not a doubt in my mind that this is not poorly written
  this.parseMessage = function (msg) {
    // Add the message to unconsumed.
    this._unconsumed += msg.toString().trim();
    // Create an array for the newly parsed commands.
    var parsedCommands = [];
    
    while (this._unconsumed != '') {
      // Get the message-length to read.
      var verbStart = this._unconsumed.indexOf('\n');
      var msgLen = parseInt(this._unconsumed.substr(0, verbStart));
      // Cut off the message length header from unconsumed.
      this._unconsumed = this._unconsumed.substr(verbStart+1);
      // Figure out how many bytes we have left to consume.
      var bytesLeft = Buffer.byteLength(this._unconsumed, 'utf8');
      // Do not process anything if we do not have enough bytes.
      if (bytesLeft < msgLen) {
        break;
      }
      // Isolate the message we are actually handling.
      var unconsumedBuffer = new Buffer(this._unconsumed);
      msg = unconsumedBuffer.slice(0, msgLen).toString();
      // Store remaining stuff in unconsumed.
      this._unconsumed = unconsumedBuffer.slice(msgLen).toString();
      // Go process this single message.
      console.log('Got message:');
      console.log(msg);
      var type = '';
      var data = {};
      var index = msg.indexOf(' ');
      if (index >= 0) { // If a body was supplied
        type = msg.substr(0, index);
        try {
          var toParse = msg.substr(index);
          data = JSON.parse(toParse);
        }
        catch(err) {
          console.log('Recieved malformed message, responding with MSG_MALFORMED');
          this.sendMessage("MSG_MALFORMED \n" + err);
          return;
        }
      } else { // No body was supplied
        type = msg;
      }
      
      parsedCommands.push({type: type, data: data});
    }
    return parsedCommands;
  }

  // If using TLS, appName is assumed to be the name of the keys.
  //process.argv.length === 3 && process.argv[2] === '--no-tls'
  this.connect = function (cert_name) {
    var client = null;
    if (!cert_name) {
      console.log("Not using TLS");
      client = net.connect({port: this.port, host:this.host}, function(err) {
        if (err) {
          console.error('There was an error establishing connection');
        }
      });
      var obj = this;
      client.on('error', function(err) {
        console.log("Connection error!")
        console.log(err)
        obj.handle('CONNECTION_ERROR', err)
      });
    } else {
      console.log("Using TLS");
      var connectOptions = {
        key: fs.readFileSync(cert_name + '.key'),
        cert: fs.readFileSync(cert_name + '.crt'),
        ca: [ fs.readFileSync('ca.crt') ],
        rejectUnauthorized: false,
        port: this.port,
        host: this.host
      };
      client = tls.connect(connectOptions, function(err) {
        if (err) {
          console.error('There was an error in establishing TLS connection');
        }
      });
      var obj = this;
      client.on('error', function(err) {
        console.log("Connection error!")
        console.log(err)
        obj.handle('CONNECTION_ERROR', err)
      });
    }
    console.log('Connected to Mycroft');
    this.cli = client;
    var obj = this;
    this.cli.on('data', function(msg) {
      var parsed = obj.parseMessage(msg);
      for(var i = 0; i < parsed.length; i++) {
        obj.handle(parsed[i].type, parsed[i].data);
      }
    });
    this.cli.on('end', function(data) {
      obj.connectionClosed(data);
    });
  }
  
  this.on = function(name, func) {
    if (!this.handlers[name]) {
      this.handlers[name] = [];
    }
    this.handlers[name].push(func);
  }
  
  this.connectionClosed = function(data) {
    this.handle('CONNECTION_CLOSED', data)
    console.log("Connection closed.");
  }
  
  this.handle = function(type, data) {
    if (this.handlers[type]) {
      for (var i=0; i<this.handlers[type].length; i++) {
        this.handlers[type][i](data);
      }
    } else {
      console.log("not handling messages:");
      console.log(type+": "+JSON.stringify(data));
    }
  }

  //Given the path to a JSON manifest, converts that manifest to a string,
  //and precedes it with the type MANIFEST
  this.sendManifest = function (path) {
    var obj = this;
    var path = path || this.manifest_loc; //use manifest location from constructor if possible
    try {
      console.log("Reading a manifest!")
      fs.readFile(path, 'utf-8', function(err, data) {
        if (err) {
          console.log("Error reading manifest:");
          console.log(err);
          obj.handle('MANIFEST_ERROR', err);
        }
        
        var json;
        try {
          json = JSON.parse(data);
        }
        catch(err) {
          console.log("Error parsing manifest:");
          console.log(err);
          obj.handle('MANIFEST_ERROR', err);
        }
        
        if (json) {
          console.log('Sending Manifest');
          obj.sendMessage('APP_MANIFEST', json);
        }
      })
    }
    catch(err) {
      console.error('Invalid file path');
      this.handle('MANIFEST_ERROR', err);
    }
  }

  this.up = function() {
    console.log('Sending App Up');
    this.status = 'up';
    this.sendMessage('APP_UP');
  }

  this.down = function() {
    console.log('Sending App Down');
    this.status = 'down';
    this.sendMessage('APP_DOWN');
  }
  
  this.in_use = function() {
    console.log('Sending App In Use');
    this.status = 'in use';
    this.sendMessage('APP_IN_USE');
  }

  this.query = function (capability, action, data, instanceId, priority) {
    console.log('Sending query!')
    var queryMessage = {
      id: uuid.v4(),
      capability: capability,
      action: action || '',
      data: data || '',
      priority: priority || 30,

    };
    if (typeof(instanceId) != 'undefined') queryMessage.instanceId = instanceId;

    this.sendMessage('MSG_QUERY', queryMessage);
  }

  this.sendSuccess = function(id, ret) {
    var querySuccessMessage = {
      id: id,
      ret: ret
    };

    this.sendMessage('MSG_QUERY_SUCCESS', querySuccessMessage);
  }

  this.sendFail = function (id, message) {
    var queryFailMessage = {
      id: id,
      message: message
    };

    this.sendMessage('MSG_QUERY_FAIL', queryFailMessage);
  }

  //Sends a message to the Mycroft global message board.
  this.broadcast = function(content) {
    message = {
      id: uuid.v4(),
      content: content
    };
    this.sendMessage('MSG_BROADCAST', message);
  }

  // Checks if the manifest was validated and returns dependencies
  this.checkManifest = function (parsed) {
    if (parsed.type === 'APP_MANIFEST_OK' || parsed.type === 'APP_MANIFEST_FAIL') {
      console.log('Response type: ' +  parsed.type);
      console.log('Response recieved: ' + JSON.stringify(parsed.data));

      if (parsed.type === 'APP_MANIFEST_OK') {
        console.log('Manifest Validated');
        return parsed.data.dependencies; //THIS WILL ALWAYS BE NIL WITH CURRENT DESIGN
      } else {
        throw 'Invalid application manifest';
      }
    }
  }

  //Sends a message of specified type. Adds byte length before message.
  //Does not need to specify a message object. (e.g. APP_UP and APP_DOWN)
  this.sendMessage = function (type, message) {
    if (typeof(message) === 'undefined') {
      message = '';
    } else {
      message = JSON.stringify(message);
    }
    var body = (type + ' ' + message).trim();
    var length = Buffer.byteLength(body, 'utf8');
    console.log('Sending Message');
    console.log(length);
    console.log(body);
    if (this.cli) {
      this.cli.write(length + '\n' + body);
    } else {
      console.log("The client connection wasn't established, so the message could not be sent.");
    }
  }

  return this;
}
`
### Controllers ###

angular.module('app.controllers', [])

.controller('AppCtrl', [
  '$scope'
  '$location'
  '$resource'
  '$rootScope'

($scope, $location, $resource, $rootScope) ->

  $scope.mycroft_host = 'localhost'
  $scope.mycroft_port = 1847
  $scope.mycroft_tls = false

  $scope.beginMycroftConnection = ->
    $scope.connecting = true
    $scope.conn = new Mycroft('app.json', $scope.mycroft_host, $scope.mycroft_port);
    
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
    if $scope.activeNavId.substring(0, id.length) == id
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
    req = http.get('http://whatismyip.akamai.com', (res) ->
      body = []
      res.on('data', (data) ->
        body.push(data)
      )
      res.on('end', () ->
        func(Buffer.concat(body))
      )
    )
    req.on('error', (err) ->
      console.log("Error retrieving ip address!")
      console.log(err.message)
    )
  
  $scope.startStream = ->
    targets = []
    for item in $scope.targets
      if item.selected 
        targets.push(item.name)
    if $scope.conn
      ctrlr = angular.element($('#'+$scope.activeNavId.substring(1))).scope()
      console.log(ctrlr)
      $scope.getIp( (ip) ->
        ctrlr.streamData(ip, (data) ->
          for type in $scope.filterTypes()
            console.log('Sending a thingy query!')
            $scope.conn.query(type, 'video_stream', data, targets)
        )
      )
    else
      $scope.addAlert("Connection not established, can't start a video.", "warning")
        
  $scope.haltStream = ->
    targets = []
    for item in $scope.targets
      if item.selected 
        targets.push(item.name)
    if $scope.conn
      for type in $scope.filterTypes
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
    cmd = _.template("vlc screen:// :sout=#transcode{vcodec=h264,scale=<%= scale %>,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:"+port+"/mycroft.sdp} :sout-keep")
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
    
])

.controller('youtube', [
  '$scope'

($scope) ->
  $scope.streamData = (ip, block)->
    block(url: $scope.url)
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
    cmd = _.template("vlc <%= url %> :sout=#transcode{vcodec=h264,scale=<%= scale %>,acodec=mpga,ab=128,channels=2,samplerate=44100,scodec=t140,soverlay}:rtp{sdp=rtsp://:"+port+"/mycroft.sdp} :sout-keep")
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