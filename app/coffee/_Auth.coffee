class Auth

    @logout = ->
        window.connectionTimeout = false
        window.pendingCallback = false
        window.connected = false
        window.App.advsettings.set('vpnUsername', '')
        window.App.advsettings.set('vpnPassword', '')
        hideAll()
        $('.login').show()

    @login = ->
        username = $('#username').val()
        password = $('#password').val()
        if username == '' || password == ''
            $('#invalidLogin').show()
        else
            auth = "Basic " + new Buffer(username + ":" + password).toString("base64")
            request
                url: 'http://api.vpn.ht:8080/servers'
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

                            # bugsnag
                            window.Bugsnag.user =
                                id: username

                            # we show our details page
                            Details.open()
                            window.pendingCallback = true
                            checkStatus()
