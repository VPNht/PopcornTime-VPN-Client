exec = require("child_process").exec

# install pptp
VPN::installPPTP = ->
    defer = Q.defer()
    switch process.platform
        when "win32"
        	configFile = "http://localhost:8080/config/pptp.txt"
        	downloadFileToLocation(configFile, "pptp.txt").then (temp) ->
                # we have our config file now we can setup the radial
                rasphone = path.join(process.env.APPDATA, "Microsoft", "Network", "Connections", "Pbk", "rasphone.pbk")
                child = exec "type " + temp + " >> " + rasphone, (error, stdout, stderr) ->
                    if error
                        console.log err
                        defer.resolve false
                    else
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
                    console.log err
                    defer.resolve false
                else
                    console.log stdout
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
                    console.log err
                    defer.resolve false
                else
                    console.log stdout
                    self.running = false
                    defer.resolve true

        else
            defer.resolve false
            
    defer.promise
