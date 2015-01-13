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
    if type == 'c'
        Debug.info('StatusMonitor', 'Checking connection')
    else
        Debug.info('StatusMonitor', 'Checking disconnection')

    if window.connected and type == 'c'
        clearTimeout window.timerMonitor
    else
        getStatus (data) ->
            if window.pendingCallback
                if data
                    win.vpnStatus = data
                    Debug.info('StatusMonitor', 'Remote results', data)
                    if window.connectionTimeout and type == 'c' and !window.connected
                        Debug.info('StatusMonitor', 'Connection timeout')
                        window.connectionTimeout = false
                        window.pendingCallback = false
                        window.connected = false
                        clearTimeout window.timerMonitor if window.timerMonitor
                        window.App.VPN.disconnect().then () ->
                            window.App.VPN.connect(window.App.VPN.protocol)

                    else if type == 'c' and data.connected == true
                        window.connectionTimeout = false
                        window.pendingCallback = false
                        window.connected = true
                        window.App.VPNClient.setVPNStatus(true)
                        clearTimeout window.timerMonitor if window.timerMonitor
                        Connected.open()
                    else if type == 'd' and data.connected == false
                        window.connectionTimeout = false
                        window.pendingCallback = false
                        window.connected = false
                        window.App.VPNClient.setVPNStatus(false)
                        Details.open()
                        clearTimeout window.timerMonitor if window.timerMonitor
                else
                    # usefull when we got a route issue
                    if window.connectionTimeout and !window.connected
                        Debug.info('StatusMonitor', 'Connection timeout or route issue')
                        window.connectionTimeout = false
                        window.pendingCallback = false
                        window.connected = false
                        clearTimeout window.timerMonitor if window.timerMonitor
                        window.App.VPN.disconnect().then () ->
                            window.App.VPN.connect(window.App.VPN.protocol)

            else
                Debug.info('StatusMonitor', 'Expired callback')

monitorStatus = (type) ->
    clearTimeout window.timerMonitor if window.timerMonitor
    window.pendingCallback = true
    window.timerMonitor = setInterval (->
        checkStatus(type)
    ), 2500
