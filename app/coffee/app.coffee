_ = require('underscore')
request = require('request')
exec = require("child_process").exec
Q = require("q")
tar = require("tar")
temp = require("temp")
zlib = require("zlib")
mv = require("mv")
fs = require("fs")
path = require("path")
gui = require('nw.gui')
win = gui.Window.get()
isDebug = false
timerMonitor = false
connectionTimeout = false

version = '0.1.0'
win.title = gui.App.manifest.name + ' VPN ' + version

win.focus()

win.on "new-win-policy", (frame, url, policy) ->
    policy.ignore()

preventDefault = (e) ->
    e.preventDefault()

window.addEventListener "dragover", preventDefault, false
window.addEventListener "drop", preventDefault, false
window.addEventListener "dragstart", preventDefault, false

$ ->
    $('#windowControlMinimize').on 'click', ->
        win.minimize()

    $('#windowControlClose').on 'click', ->
        win.close()
