getStatus = (callback) ->
    request
        url: 'https://vpn.ht/status?json'
        timeout: 3000
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
                        Debug.error('StatusMonitor', 'Connection timeout')
                        OpenVPNManagement.getLog (err, log) ->
                            Debug.info('StatusMonitor', 'OpenVPN log', {err: err, log: log})
                            window.connectionTimeout = false
                            window.pendingCallback = false
                            window.connected = false
                            clearTimeout window.timerMonitor if window.timerMonitor
                            clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
                            window.App.VPN.disconnect().then () ->
                                window.App.VPN.connect(window.App.VPN.protocol)

                    else if type == 'c' and data.connected == true
                        window.connectionTimeout = false
                        window.pendingCallback = false
                        window.connected = true
                        # force update of PT url for YTS
                        if typeof parent.App.Providers.delete == 'function'
                            parent.App.settings.ytsAPI.url = 'https://yts.re/api/'
                            parent.App.Providers.delete('Yts')
                        window.App.VPNClient.setVPNStatus(true)
                        clearTimeout window.timerMonitor if window.timerMonitor
                        clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
                        Connected.open()

                    else if type == 'd' and data.connected == false
                        disconnectUser()
                else
                    # usefull when we got a route issue
                    if window.connectionTimeout and !window.connected
                        Debug.error('StatusMonitor', 'Connection timeout or route issue')
                        OpenVPNManagement.getLog (err, log) ->
                            Debug.info('StatusMonitor', 'OpenVPN log', {err: err, log: log})
                            window.connectionTimeout = false
                            window.pendingCallback = false
                            window.connected = false
                            clearTimeout window.timerMonitor if window.timerMonitor
                            clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
                            window.App.VPN.disconnect().then () ->
                                window.App.VPN.connect(window.App.VPN.protocol)

            else
                Debug.info('StatusMonitor', 'Expired callback')

disconnectUser = ->
    # wait 5 sec to give time to routes
    setTimeout (->
        Debug.info('disconnectUser', 'Disconnected')
        window.connectionTimeout = false
        window.pendingCallback = false
        window.connected = false
        window.App.VPNClient.setVPNStatus(false)
        Details.open()
        clearTimeout window.timerMonitor if window.timerMonitor
        clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
    ), 5000

monitorStatus = (type) ->
    clearTimeout window.timerMonitor if window.timerMonitor
    window.pendingCallback = true
    window.timerMonitor = setInterval (->
        checkStatus(type)
    ), 2500
