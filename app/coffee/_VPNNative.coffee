# install pptp
VPN::installPPTP = ->
    defer = Q.defer()
    switch process.platform
        when "win32"
        	configFile = "https://client.vpn.ht/config/pptp.txt"
        	downloadFileToLocation(configFile, "pptp.txt").then (temp) ->
                # we have our config file now we can setup the radial
                rasphone = path.join(process.env.APPDATA, "Microsoft", "Network", "Connections", "Pbk", "rasphone.pbk")
                child = exec "type " + temp + " >> " + rasphone, (error, stdout, stderr) ->
                    if error
                        Debug.error('InstallError', error)
                        defer.resolve false
                    else

                        Debug.info('InstallLog', 'PPTP installation successfull')
                        Debug.info('InstallLog', stdout)

                        window.App.advsettings.set("vpnPPTP", true)
                        defer.resolve true

        else
            defer.resolve false

    defer.promise

# pptp connection
VPN::connectPPTP = ->
    self = this
    defer = Q.defer()
    switch process.platform
        when "win32"
            rasdial = path.join(process.env.SystemDrive, 'Windows', 'System32', 'rasdial.exe')
            authString = window.App.settings.vpnUsername + " " + window.App.settings.vpnPassword

            child = exec rasdial + " vpnht " + authString, (error, stdout, stderr) ->
                if error
                    Debug.error('ConnectError', error)
                    defer.resolve false
                else
                    # if not connected after 10sec we send timeout
                    setTimeout (->
                        window.connectionTimeout = true;
                    ), 10000

                    Debug.info('ConnectLog', 'PPTP connection successfull')
                    Debug.info('ConnectLog', stdout)

                    self.protocol = 'pptp'
                    self.running = true
                    defer.resolve true

        else
            defer.resolve false

    defer.promise

VPN::disconnectPPTP = ->
    self = this
    defer = Q.defer()
    switch process.platform
        when "win32"
            rasdial = path.join(process.env.SystemDrive, 'Windows', 'System32', 'rasdial.exe')
            child = exec rasdial + " /disconnect", (error, stdout, stderr) ->
                if error
                    Debug.error('DisconnectError', error)
                    defer.resolve false
                else

                    Debug.info('DisconnectLog', 'PPTP disconnected successfully')
                    Debug.info('DisconnectLog', stdout)

                    self.running = false
                    defer.resolve true

        else
            defer.resolve false

    defer.promise
