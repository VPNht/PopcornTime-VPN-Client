exec = require("child_process").exec
VPN::installOpenVPN = ->
    self = this
    switch process.platform

        when "darwin"
        	tarball = "http://localhost:8080/bin/openvpn-mac.tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)

        when "linux"
        	arch = (if process.arch is "ia32" then "x86" else process.arch)
        	tarball = "http://localhost:8080/bin/openvpn-linux-" + arch + ".tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->
                    self.downloadOpenVPNConfig().then (err) ->
                        window.App.advsettings.set("vpnOVPN", true)

        when "win32"
            arch = (if process.arch is "ia32" then "x86" else process.arch)
            tarball = "http://localhost:8080/bin/openvpn-win-" + arch + ".tar.gz"
            downloadTarballAndExtract(tarball).then (temp) ->
                # we install openvpn
                copyToLocation(getInstallPathOpenVPN(), temp).then (err) ->

                    # we install openvpn
                    args = [
                        "/S"
                        "/SELECT_TAP=1"
                        "/SELECT_SERVICE=1"
                        "/SELECT_SHORTCUTS=1"
                        "/SELECT_OPENVPNGUI=1"
                        "/D=" + getInstallPathOpenVPN('service')
                    ]
                    # path to our install file
                    openvpnInstall = path.join(getInstallPathOpenVPN(), 'openvpn-install.exe')
                    runas openvpnInstall, args, (success) ->
                        return success

VPN::downloadOpenVPNConfig = ->

	# make sure path exist
	try
		fs.mkdirSync getInstallPathOpenVPN() unless fs.existsSync(getInstallPathOpenVPN())
	catch e
		console.log e

	configFile = "http://localhost:8080/config/vpnht.ovpn"
	downloadFileToLocation(configFile, "config.ovpn").then (temp) ->
		copyToLocation path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn"), temp

VPN::disconnectOpenVPN = ->
	defer = Q.defer()
	self = this

	# need to run first..
	defer.resolve()	unless @running
	if process.platform is "win32"
		netBin = path.join(process.env.SystemDrive, "Windows", "System32", "net.exe")

		# we need to stop the service
		runas netBin, ["stop", "OpenVPNHTService"], (success) ->
            # update ip
    		self.running = false
    		console.log "openvpn stoped"
    		defer.resolve()
	else
		getPidOpenVPN().then (pid) ->
			if pid
                # kill the process
				runas "kill", ["-9", pid], (success) ->
                    # we'll delete our pid file
                    try
                        fs.unlinkSync path.join(getInstallPathOpenVPN(), "vpnht.pid")
                    catch e
                        console.log e
                    self.running = false
                    console.log "openvpn stoped"
                    defer.resolve()
			else
				console.log "no pid found"
				self.running = false
				defer.reject "no_pid_found"
			return

	defer.promise

VPN::connectOpenVPN = ->
    defer = Q.defer()
    fs = require("fs")
    self = this
    tempPath = temp.mkdirSync("popcorntime-vpnht")
    tempPath = path.join(tempPath, "o1")
    fs.writeFile tempPath, window.App.settings.vpnUsername + "\n" + window.App.settings.vpnPassword, (err) ->
        if err
            defer.reject err
        else

            # ok we have our auth file
            # now we need to make sure we have our openvpn.conf
            vpnConfig = path.resolve(getInstallPathOpenVPN(), "vpnht.ovpn")
            if fs.existsSync(vpnConfig)
                args = [
                    "--daemon"
                    "--writepid"
                    path.join(getInstallPathOpenVPN(), "vpnht.pid")
                    "--log-append"
                    path.join(getInstallPathOpenVPN(), "vpnht.log")
                    "--config"
                    vpnConfig
                    "--auth-user-pass"
                    tempPath
                ]

                if process.platform is "linux"

                    # in linux we need to add the --dev tun0
                    args = [
                        "--daemon"
                        "--writepid"
                        path.join(getInstallPathOpenVPN(), "vpnht.pid")
                        "--log-append"
                        path.join(getInstallPathOpenVPN(), "vpnht.log")
                        "--dev"
                        "tun0"
                        "--config"
                        vpnConfig
                        "--auth-user-pass"
                        tempPath
                    ]

                # execption for windows openvpn path
                if process.platform is "win32"

                    # we copy our openvpn.conf for the windows service
                    newConfig = path.resolve(getInstallPathOpenVPN(), "config", "openvpn.ovpn")
                    copy vpnConfig, newConfig, (err) ->
                        console.log err if err
                        fs.appendFile newConfig, "\r\nauth-user-pass " + tempPath.replace(/\\/g, "\\\\"), (err) ->
                            netBin = path.join(process.env.SystemDrive, "Windows", "System32", "net.exe")
                            runas netBin, ['start', 'OpenVPNHTService'], (success) ->
                                self.running = true
                                self.protocol = 'openvpn'
                                console.log "openvpn launched"
                                defer.resolve()

                else
                    # openvpn bin path for mac & linux
                    openvpn = path.resolve(getInstallPathOpenVPN(), "openvpn")
                    # make sure we have our bin
                    if fs.existsSync(openvpn)

                        # we'll delete our pid file to
                        # prevent any connexion error
                        try
                            fs.unlinkSync path.join(getInstallPathOpenVPN(), "vpnht.pid")   if fs.existsSync(path.join(getInstallPathOpenVPN(), "vpnht.pid"))
                        catch e
                            console.log e
                        runas openvpn, args, (success) ->
                            self.running = true
                            self.protocol = 'openvpn'
                            defer.resolve()

            else
                defer.reject "openvpn_config_not_found"
    defer.promise

# we look if we have bin
haveBinariesOpenVPN = ->
	switch process.platform
		when "darwin", "linux"
			return fs.existsSync(path.resolve(getInstallPathOpenVPN(), "openvpn"))
		when "win32"
			return fs.existsSync(path.resolve(getInstallPathOpenVPN(), "bin", "openvpn.exe"))
		else
			return false

# get pid of openvpn
# used in linux and mac
getPidOpenVPN = ->
	defer = Q.defer()
	fs.readFile path.join(getInstallPathOpenVPN(), "vpnht.pid"), "utf8", (err, data) ->
		if err
			defer.resolve false
		else
			defer.resolve data.trim()
		return

	defer.promise

# helper to get vpn install path
getInstallPathOpenVPN = (type) ->
    type = type || false
	if type == 'service'
        return path.join(process.env.USERPROFILE, 'vpnht');
    else
        return path.join(process.cwd(), "openvpn")
