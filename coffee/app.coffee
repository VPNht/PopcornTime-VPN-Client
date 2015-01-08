# Load native UI library
gui = require('nw.gui')
version = '0.1.0'

# Get window object (!= $(window))
win = gui.Window.get()

# Debug flag
isDebug = false

# Set the app title (for Windows mostly)
win.title = gui.App.manifest.name + ' VPN ' + version

# Focus the window when the app opens
win.focus()

# Cancel all new windows (Middle clicks / New Tab)
win.on "new-win-policy", (frame, url, policy) ->
    policy.ignore()

# Prevent dragging/dropping files into/outside the window
preventDefault = (e) ->
    e.preventDefault()

window.addEventListener "dragover", preventDefault, false
window.addEventListener "drop", preventDefault, false
window.addEventListener "dragstart", preventDefault, false

########################################################

$ ->

    $('#windowControlMinimize').on 'click', ->
        win.minimize()

    $('#windowControlClose').on 'click', ->
        win.close()
