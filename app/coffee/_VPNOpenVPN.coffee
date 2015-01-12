VPN::installOpenVPN = ->
    self = this
    defer = Q.defer()
    switch process.platform

        when "darwin"
        	tarball = "https://client.vpn.ht/bin/openvpn-mac.tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)
                        defer.resolve()

        when "linux"
        	arch = (if process.arch is "ia32" then "x86" else process.arch)
        	tarball = "https://client.vpn.ht/bin/openvpn-linux-" + arch + ".tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)
                        defer.resolve()

        when "win32"
            tarball = "https://client.vpn.ht/bin/openvpn-win.tar.gz"
            downloadTarballAndExtract(tarball).then (temp) ->
                # we install openvpn
                copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->

                        # we install tap
                        args = [
                            "/S"
                        ]

                        # path to our install file
                        tapInstall = path.join(getInstallPathOpenVPN(), 'tap.exe')
                        Debug.info('installOpenVPN', 'Tap install', {tapInstall:tapInstall, args:args})

                        runas tapInstall, args, (success) ->
                            timerCheckDone = setInterval (->
                                haveTap = haveBinariesTAP()
                                Debug.info('installOpenVPN', 'Waiting tap installation', {haveTap:haveTap})
                                if haveTap
                                    # kill the timer to prevent looping
                                    window.clearTimeout(timerCheckDone)
                                    # temp fix add 5 sec timer once we have all bins
                                    # to make sure the service and tap are ready
                                    setTimeout (->
                                        window.App.advsettings.set("vpnOVPN", true)
                                        defer.resolve()
                                    ), 5000
                            ), 1000
    defer.promise

VPN::downloadOpenVPNConfig = ->
	# make sure path exist
	try
		fs.mkdirSync getInstallPathOpenVPN() unless fs.existsSync(getInstallPathOpenVPN())
	catch e
        Debug.error('downloadOpenVPNConfig', 'Error', e)

    configFile = "https://client.vpn.ht/config/vpnht.ovpn"
    Debug.info('downloadOpenVPNConfig', 'Downloading OpenVPN configuration file', {configFile: configFile})
	downloadFileToLocation(configFile, "config.ovpn").then (temp) ->
		copyToLocation path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn"), temp

VPN::disconnectOpenVPN = ->
	defer = Q.defer()
	self = this

	OpenVPNManagement.send 'signal SIGTERM', (err, data) ->
        defer.resolve()

	defer.promise

VPN::connectOpenVPN = ->
    defer = Q.defer()
    fs = require("fs")
    self = this
    tempPath = temp.mkdirSync("popcorntime-vpnht")
    tempPath = path.join(tempPath, "o1")
    # now we need to make sure we have our openvpn.conf
    vpnConfig = path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn")
    if fs.existsSync(vpnConfig)

        if process.platform is "linux"

            # in linux we need to add the --dev tun0
            args = [
                "--daemon"
                "--management"
                "127.0.0.1"
                "1337"
                "--dev"
                "tun0"
                "--config"
                "'"+vpnConfig+"'"
                "--management-query-passwords"
                "--management-hold"
                "--script-security"
                "2"
            ]

        else if process.platform is "darwin"

            # darwin
            args = [
                "--daemon"
                "--management"
                "127.0.0.1"
                "1337"
                "--config"
                '\\"'+vpnConfig+'\\"'
                "--management-query-passwords"
                "--management-hold"
                "--script-security"
                "2"
            ]
        else

            # windows cant run in daemon
            args = [
                "--management"
                "127.0.0.1"
                "1337"
                "--config"
                "'"+vpnConfig+"'"
                "--management-query-passwords"
                "--management-hold"
                "--script-security"
                "2"
            ]

        if process.platform is "win32"
            openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn.exe")
        else
            openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn")

        # make sure we have our bin
        if fs.existsSync(openvpn)

            # need to escape
            if process.platform == "darwin"
                openvpn = '\\"'+openvpn+'\\"'
            else
                openvpn = "'"+openvpn+"'"

            spawnas openvpn, args, (success) ->
                self.running = true
                self.protocol = 'openvpn'
                # if not connected after 30sec we send timeout
                setTimeout (->
                    window.connectionTimeout = true;
                ), 30000

                # we should monitor the management port
                # when it's ready we connect

                monitorManagementConsole ->
                    OpenVPNManagement.send 'hold release', (err, data) ->
                        OpenVPNManagement.send 'username "Auth" "'+window.App.settings.vpnUsername+'"\npassword "Auth" "'+window.App.settings.vpnPassword+'"', (err, data) ->
                            defer.resolve()

        else
            Debug.error('connectOpenVPN', 'OpenVPN bin not found', {openvpn: openvpn})


    else
        defer.reject "openvpn_config_not_found"

    defer.promise

# openvpn wait management interface to be ready
monitorManagementConsole = (callback) ->
    clearTimeout window.timerMonitorConsole if window.timerMonitorConsole
    window.pendingCallback = true
    window.timerMonitorConsole = setInterval (->
        getPidOpenVPN()
            .then (pid) ->
                if pid != false
                    clearTimeout(window.timerMonitorConsole)
                    callback()
            .catch (err) ->
                clearTimeout(window.timerMonitorConsole)
    ), 2000

# we look if we have bin
haveBinariesOpenVPN = ->
	switch process.platform
		when "darwin", "linux"
			return fs.existsSync(path.resolve(getInstallPathOpenVPN(), "openvpn"))
		when "win32"
			return fs.existsSync(path.resolve(getInstallPathOpenVPN(), "openvpn.exe"))
		else
			return false

haveBinariesTAP = ->
	switch process.platform
		when "win32"
            # looks for tap exe
			return fs.existsSync(path.resolve(process.env.ProgramW6432 || process.env.ProgramFiles, "TAP-Windows", "bin", "tapinstall.exe"))
		else
			return false

# get pid of openvpn
# used in linux and mac
getPidOpenVPN = ->
	defer = Q.defer()
	OpenVPNManagement.send 'pid', (err, data) ->
        defer.resolve false if err
        if data and data.indexOf("SUCCESS") > -1
            defer.resolve data.split("=")[1]
        else
            defer.resolve false

	defer.promise

# helper to get vpn install path
getInstallPathOpenVPN = (type) ->
    type = type || false
    return path.join(process.cwd(), ".openvpnht")
