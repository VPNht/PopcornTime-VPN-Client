request = require('request')

checkStatus = ->
    request
        url: 'https://vpn.ht/status?json'
        , (error, response, body) ->
            if response.statusCode == 200
                body = JSON.parse(body)
                win.vpnStatus = body

                if body.connected == true
                    Connected.open()
