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

# checkStatus type
# c = connect minitoring
# d = disconnect monitoring
checkStatus = (type) ->
    type = type || 'c'
    console.log('monitoring status....', type)
    getStatus (data) ->
        if data
            win.vpnStatus = data
            console.log(data.connected)
            if type == 'c' and data.connected == true
                Connected.open()
                window.clearTimeout timerMonitor if timerMonitor
            else if type == 'd' and data.connected == false
                Details.open()
                window.clearTimeout timerMonitor if timerMonitor

monitorStatus = (type) ->
    timerMonitor = setInterval (->
        checkStatus(type)
    ), 2500
