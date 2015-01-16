VPN::installOpenVPN = ->
    self = this
    defer = Q.defer()

    openvpnPath = getInstallPathOpenVPN()

    # check if we have path
    if fs.existsSync openvpnPath
        # remove all previous install
        try
            rmdirSync openvpnPath
        catch e
            Debug.error('installOpenVPN', 'Error', e)

    switch process.platform

        when "darwin"
        	tarball = "https://client.vpn.ht/bin/openvpn-mac.tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(openvpnPath, temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)
                        defer.resolve()

        when "linux"
        	arch = (if process.arch is "ia32" then "x86" else process.arch)
        	tarball = "https://client.vpn.ht/bin/openvpn-linux-" + arch + ".tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(openvpnPath, temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)
                        defer.resolve()

        when "win32"
            tarball = "https://client.vpn.ht/bin/openvpn-win.tar.gz"
            downloadTarballAndExtract(tarball).then (temp) ->
                # we install openvpn
                copyToLocation(openvpnPath, temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->

                        # we install tap
                        args = [
                            "/S"
                        ]

                        # path to our install file
                        tapInstall = path.join(openvpnPath, 'tap.exe')
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
            upScript = path.resolve(getInstallPathOpenVPN(), "script.up").replace(" ", "\\\\ ")
            downScript = path.resolve(getInstallPathOpenVPN(), "script.down").replace(" ", "\\\\ ")
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
                "--up"
                '\\"'+upScript+'\\"'
                "--down"
                '\\"'+downScript+'\\"'
            ]
        else
            # win
            upScript = path.resolve(getInstallPathOpenVPN(), "up.cmd").replace(/\\/g, '\\\\')
            # windows cant run in daemon
            args = [
                "--management"
                "127.0.0.1"
                "1337"
                "--config"
                '"'+vpnConfig+'"'
                "--management-query-passwords"
                "--management-hold"
                "--script-security"
                "2"
                "--up"
                '"'+upScript+'"'
            ]

        if process.platform is "win32"
            openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn.exe")
        else
            openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn")

        Debug.info('connectOpenVPN', 'OpenVPN', {bin: openvpn, args: args})

        # make sure we have our bin
        if fs.existsSync(openvpn)

            # need to escape
            if process.platform == "darwin"
                openvpn = '\\"'+openvpn+'\\"'
            else if process.platform == "win32"
                openvpn = '"'+openvpn+'"'
            else
                openvpn = "'"+openvpn+"'"

            spawnas openvpn, args, (success) ->
                self.running = true
                self.protocol = 'openvpn'

                # we should monitor the management port
                # when it's ready we connect

                monitorManagementConsole ->
                    # wait 2s
                    setTimeout (->
                        Debug.info('connectOpenVPN', 'Hold release')
                        OpenVPNManagement.send 'hold release', (err, data) ->
                            # wait 2s
                            setTimeout (->
                                Debug.info('connectOpenVPN', 'Sending username')
                                OpenVPNManagement.send 'username "Auth" "'+window.App.settings.vpnUsername+'"', (err, data) ->
                                    # wait 2s
                                    setTimeout (->
                                        Debug.info('connectOpenVPN', 'Sending password')
                                        OpenVPNManagement.send 'password "Auth" "'+window.App.settings.vpnPassword+'"', (err, data) ->

                                            # if not connected after 30sec we send timeout
                                            Debug.info('connectOpenVPN', 'Authentification sent')
                                            clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
                                            window.connectionTimeoutTimer = setTimeout (->
                                                window.connectionTimeout = true;
                                            ), 60000
                                            defer.resolve()
                                    ), 2000
                            ), 2000
                    ), 2000
        else
            Debug.error('connectOpenVPN', 'OpenVPN bin not found', {openvpn: openvpn})
            defer.reject "openvpn_bin_not_found"


    else
        Debug.error('connectOpenVPN', 'OpenVPN config not found', {vpnConfig: vpnConfig})
        defer.reject "openvpn_config_not_found"

    defer.promise

# openvpn wait management interface to be ready
monitorManagementConsole = (callback) ->
    Debug.info('monitorManagementConsole', 'Waiting OpenVPN monitor interface to be ready on port 1337')
    clearTimeout window.timerMonitorConsole if window.timerMonitorConsole
    window.pendingCallback = true
    window.timerMonitorConsole = setInterval (->
        canConnectOpenVPN()
            .then (err) ->
                if err != false
                    Debug.info('monitorManagementConsole', 'Interface ready')
                    clearTimeout(window.timerMonitorConsole)
                    callback()
            .catch (err) ->
                clearTimeout(window.timerMonitorConsole)
    ), 2000

# we look if we have bin
haveBinariesOpenVPN = ->
	switch process.platform
		when "darwin", "linux"
            bin = path.resolve(getInstallPathOpenVPN(), "openvpn")
            exist = fs.existsSync(bin)
            Debug.info('haveBinariesOpenVPN', 'Checking OpenVPN binaries', {bin: bin, exist: exist})
            return exist
		when "win32"
            bin = path.resolve(getInstallPathOpenVPN(), "openvpn.exe")
            exist = fs.existsSync(bin)
            Debug.info('haveBinariesOpenVPN', 'Checking OpenVPN binaries', {bin: bin, exist: exist})
            return exist
		else
			return false

haveBinariesTAP = ->
	switch process.platform
		when "win32"
            bin = path.resolve(process.env.ProgramW6432 || process.env.ProgramFiles, "TAP-Windows", "bin", "devcon.exe")
            exist = fs.existsSync(bin)
            Debug.info('haveBinariesTAP', 'Checking TAP binaries', {bin: bin, exist: exist})
            return exist
		else
			return false

haveScriptsOpenVPN = ->
	switch process.platform
		when "darwin"
            script = path.resolve(getInstallPathOpenVPN(), "script.up")
            exist = fs.existsSync(script)
            Debug.info('haveScripts', 'Checking OpenVPN scripts', {script: script, exist:exist})
            return exist
		when "win32"
            script = path.resolve(getInstallPathOpenVPN(), "up.cmd")
            exist = fs.existsSync(script)
            Debug.info('haveScripts', 'Checking OpenVPN scripts', {script: script, exist:exist})
            return exist
		else
			return true

# get pid of openvpn
# used in linux and mac
getPidOpenVPN = ->
	defer = Q.defer()
	OpenVPNManagement.send 'pid', (err, data) ->
        if err
            Debug.error('getPidOpenVPN', 'Get OpenVPN pid', {err: err, data: data})
            defer.resolve false

        else if data and data.indexOf("SUCCESS") > -1
            Debug.info('getPidOpenVPN', 'Get OpenVPN pid', {data: data})
            defer.resolve data.split("=")[1]

        else
            Debug.info('getPidOpenVPN', 'Get OpenVPN pid', {data: data})
            defer.resolve false

	defer.promise

canConnectOpenVPN = ->
	defer = Q.defer()
	OpenVPNManagement.send 'pid', (err, data) ->
        Debug.info('canConnectOpenVPN', 'Validate OpenVPN Process', {err: err, data: data})
        if err
            defer.resolve false
        else
            defer.resolve true

	defer.promise

# helper to get vpn install path
getInstallPathOpenVPN = (type) ->
    type = type || false
    binpath = path.join(process.cwd(), ".openvpnht")
    return binpath
