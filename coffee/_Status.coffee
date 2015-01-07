request = require('request')

getStatus = (callback) ->
    request
        url: 'https://vpn.ht/status?json'
        , (error, response, body) ->
            if response.statusCode == 200
                body = JSON.parse(body)
                callback body
            else
                callback false


checkStatus = ->
    getStatus (data) ->
        if data
            win.vpnStatus = data
            if data.connected == true
                Connected.open()
