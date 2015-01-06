# Load native UI library
gui = require('nw.gui')

# Get window object (!= $(window))
win = gui.Window.get()

# Debug flag
isDebug = true

# Set the app title (for Windows mostly)
win.title = gui.App.manifest.name + ' ' + gui.App.manifest.version

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

autoLogin = ->
    # we check if we have existing login and we auto login
    if window.App and window.App.settings.vpnUsername and window.App.settings.vpnPassword
        $('#username').val(window.App.settings.vpnUsername)
        $('#password').val(window.App.settings.vpnPassword)
        login()
