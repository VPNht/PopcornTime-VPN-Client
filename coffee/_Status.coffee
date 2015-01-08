request = require('request')
timerMonitor = false

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
    console.log('monitoring status....')
    getStatus (data) ->
        if data
            win.vpnStatus = data
            console.log(data.connected)
            if data.connected eq true
                Connected.open()
                window.clearTimeout timerMonitor if timerMonitor

monitorStatus = ->
    timerMonitor = setInterval (->
        checkStatus()
    ), 2500
