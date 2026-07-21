-- Runs automatically when the plugin loads. Keeps a single shared
-- RemoteServer instance alive for the life of the catalog session.

_G.RemoteSliderControlServer = require 'RemoteServer'
_G.RemoteSliderControlServer.start()
