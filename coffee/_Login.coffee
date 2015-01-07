request = require('request')
$ ->
    $('#username').keypress (e) ->
        login() if e.which is 13

    $('#password').keypress (e) ->
        login() if e.which is 13

    $('#login').on 'click', ->
        login()

    $('#logoutBtn').on 'click', ->
        logout()

    $('#createAccount').on 'click', ->
        gui.Shell.openExternal('https://vpn.ht/popcorntime');

    $('#helpBtn').on 'click', ->
        gui.Shell.openExternal('https://vpnht.zendesk.com/hc/en-us');

    $('#forgotPassword').on 'click', ->
        gui.Shell.openExternal('https://vpn.ht/forgot');

    $('#showDetail').on 'click', ->
        Details.open()

logout = ->
    window.App.advsettings.set('vpnUsername', '')
    window.App.advsettings.set('vpnPassword', '')
    $('.login').show()
    $('.details').hide()
    $('.status').hide()
    $('.installScript').hide()

login = ->
    username = $('#username').val()
    password = $('#password').val()
    if username == '' || password == ''
        $('#invalidLogin').show()
    else
        auth = "Basic " + new Buffer(username + ":" + password).toString("base64")
        request
            url: 'https://vpn.ht/servers'
            headers:
                Authorization: auth
            , (error, response, body) ->
                if response.statusCode == 401
                    $('#invalidLogin').show()
                else
                    if window
                        # we have successful login so we save it to PT
                        window.App.advsettings.set('vpnUsername', username)
                        window.App.advsettings.set('vpnPassword', password)

                        # we save our user info
                        window.vpn = JSON.parse(body)

                        # we show our details page
                        Details.open()
                        checkStatus()
