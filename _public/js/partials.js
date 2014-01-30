angular.module('partials', [])
.run(['$templateCache', function($templateCache) {
  return $templateCache.put('/partials/connect.html', [
'',
'<div style="width: 100%;">',
'  <accordion>',
'    <accordion-group>',
'      <accordion-heading>Connection Details<i class="pull-right glyphicon glyphicon-chevron-down"></i></accordion-heading>',
'      <div class="well"><span>Host</span>',
'        <input type="text" id="host" ng-model="mycroft_host"><span>Port</span>',
'        <input type="number" id="port" ng-model="mycroft_port">',
'        <label class="checkbox inline"></label>',
'        <input type="checkbox" id="tls_status" ng-model="mycroft_tls"><span>Use TLS</span>',
'        <div ng-class="{disabled: connecting}" ng-click="beginMycroftConnection()" class="btn btn-primary pull-right">Connect</div>',
'      </div>',
'    </accordion-group>',
'  </accordion>',
'</div>',''].join("\n"));
}])
.run(['$templateCache', function($templateCache) {
  return $templateCache.put('/partials/file.html', [
'',
'<div ng-app="ng-app">',
'  <div ng-controller="file" id="file">',
'    <h1>Local File Streaming</h1>',
'    <div style="padding: 8px;" class="panel panel-default">',
'      <p>Select a file (or files) to start streaming from your machine.</p>',
'      <input style="text-align: center" id="fileDialog" type="file" multiple>',
'      <p>Stream resolution scale ',
'        <input type="number" id="screen_scale" step="0.1" min="0.1" max="100" default="100" ng-model="scale"><small>%</small>',
'      </p><small>(Note: vlc must be on your system path.)</small>',
'    </div>',
'  </div>',
'</div>',''].join("\n"));
}])
.run(['$templateCache', function($templateCache) {
  return $templateCache.put('/partials/screen.html', [
'',
'<div ng-app="ng-app">',
'  <div ng-controller="screen" id="screen">',
'    <h1>Local Display Streaming</h1>',
'    <div style="padding: 8px;" class="panel panel-default">',
'      <p>Stream your screen and audio to Mycroft</p>',
'      <p>Stream resolution scale ',
'        <input type="number" id="screen_scale" step="0.1" min="0.1" max="100" default="100" ng-model="scale"><small>%</small>',
'      </p><small>(Note: vlc must be on your system path.)</small>',
'    </div>',
'  </div>',
'</div>',''].join("\n"));
}])
.run(['$templateCache', function($templateCache) {
  return $templateCache.put('/partials/targets.html', [
'',
'<ul class="unstyled">',
'  <li ng-repeat="target in targets">',
'    <input type="checkbox" ng-model="target.selected"><span class="{{target.type}}"> {{target.name}}</span>',
'  </li>',
'</ul>',''].join("\n"));
}])
.run(['$templateCache', function($templateCache) {
  return $templateCache.put('/partials/youtube.html', [
'',
'<div ng-app="ng-app">',
'  <div ng-controller="youtube" id="youtube">',
'    <h1>Web Video Streaming</h1>',
'    <div style="padding: 8px;" class="panel panel-default">',
'      <p>Enter the full URL of a youtube or vimeo video to stream</p>',
'      <input type="url" id="youtube_url" ng-model="url">',
'    </div>',
'  </div>',
'</div>',''].join("\n"));
}]);