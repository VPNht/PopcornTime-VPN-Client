exec = require("child_process").exec

# install pptp
VPN::installPPTP = ->

    switch process.platform
        when "win32"
        	configFile = "http://localhost:8080/config/pptp.txt"
        	downloadFileToLocation(configFile, "pptp.txt").then (temp) ->
                # we have our config file now we can setup the radial
                rasphone = path.join(process.env.APPDATA, "Microsoft", "Network", "Connections", "Pbk", "rasphone.pbk")
                child = exec "type " + temp + " >> " + rasphone, (error, stdout, stderr) ->
                    if error
                        console.log err
                    else
                        console.log stdout

# pptp connection
VPN::connectPPTP = ->

    switch process.platform
        when "win32"
            rasdial = path.join(process.env.SystemDrive, 'Windows', 'System32', 'rasdial.exe')
            authString = window.App.settings.vpnUsername + " " + window.App.settings.vpnPassword

            child = exec rasdial + " vpnht " + authString, (error, stdout, stderr) ->
                if error
                    console.log err
                else
                    console.log stdout
