'use strict'

App = angular.module('app', [
  'ngCookies'
  'ngResource'
  'ngRoute'
  'app.controllers'
  'partials'
  'ui.bootstrap.tpls'
  'ui.bootstrap.accordion'
  'ui.bootstrap.alert'
  'ui.bootstrap.progressbar'
])

App.config([
  '$routeProvider'
  '$locationProvider'

($routeProvider, $locationProvider, config) ->

  $routeProvider

    .when('/youtube', {templateUrl: '/partials/youtube.html'})
    .when('/file', {templateUrl: '/partials/file.html'})
    .when('/screen', {templateUrl: '/partials/screen.html'})

    # Catch all
    .otherwise({redirectTo: '/file'})

  # Without server side support html5 must be disabled.
  $locationProvider.html5Mode(false)
])
