getStatus = (callback) ->
    request
        url: 'https://vpn.ht/status?json'
        , (error, response, body) ->
            return callback false if error
            if response and response.statusCode == 200
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
            console.log('connected', data.connected)
            if window.connectionTimeout and type == 'c'
                console.log('connection timeout, trying again')
                window.connectionTimeout = false
                clearTimeout window.timerMonitor if window.timerMonitor
                window.App.VPN.disconnect().then () ->
                    window.App.VPN.connect(window.App.VPN.protocol)

            else if type == 'c' and data.connected == true
                window.App.VPNClient.setVPNStatus(true)
                clearTimeout window.timerMonitor if window.timerMonitor
                Connected.open()
            else if type == 'd' and data.connected == false
                window.App.VPNClient.setVPNStatus(false)
                Details.open()
                clearTimeout window.timerMonitor if window.timerMonitor
        else
            # usefull when we got a route issue
            if window.connectionTimeout
                console.log('connection timeout or route issue, trying again')
                window.connectionTimeout = false
                clearTimeout window.timerMonitor if window.timerMonitor
                window.App.VPN.disconnect().then () ->
                    window.App.VPN.connect(window.App.VPN.protocol)

monitorStatus = (type) ->
    clearTimeout window.timerMonitor if window.timerMonitor
    window.timerMonitor = setInterval (->
        checkStatus(type)
    ), 2500
