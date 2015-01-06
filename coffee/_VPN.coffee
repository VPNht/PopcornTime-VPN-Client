request = require("request")
Q = require("q")
tar = require("tar")
temp = require("temp")
zlib = require("zlib")
mv = require("mv")
fs = require("fs")
path = require("path")

VPN = ->
	return new VPN() unless this instanceof VPN
	@running = false
	@ip = false

temp.track()
VPN::isInstalled = ->

	# just to make sure we have a config value
	if haveBinaries()

		# we'll fallback to check if it's been installed
		# form the app ?
		installed = App.advsettings.get("vpn")
		if installed
			return true
		else
			return false
	false

VPN::isDisabled = ->

	#disabled on demand
	disabled = App.advsettings.get("vpnDisabledPerm")
	if disabled
		true
	else
		false

VPN::isRunning = (checkOnStart) ->
	defer = Q.defer()
	self = this
	checkOnStart = checkOnStart or false
	if @isInstalled()
		if process.platform is "win32"
			root = undefined
			if process.env.SystemDrive
				root = process.env.SystemDrive
			else
				root = process.env.SystemRoot.split(path.sep)[0]

				# fallback if we dont get it
				root = "C:"	if root.length is 0
			root = path.join(root, "Windows", "System32", "sc.exe")
			exec = require("child_process").exec
			child = exec(root + " query OpenVPNService | findstr /i \"STATE\"", (error, stdout, stderr) ->
				if error isnt null
					console.log "exec error: " + error
					1
				else
					if stdout.trim().indexOf("RUNNING") > 1
						self.running = true
						defer.resolve true

						# if its the call from the startup
						# we'll trigger a reload on our UI
						# to show the connexion state
						App.vent.trigger "movies:list"	if checkOnStart
					else
						self.running = false
						defer.resolve false
				return
			)
		else
			getPid().then (pid) ->
				self.getIp()
				if pid
					self.running = true
					defer.resolve true

					# if its the call from the startup
					# we'll trigger a reload on our UI
					# to show the connexion state
					App.vent.trigger "movies:list"	if checkOnStart
				else
					self.running = false
					defer.resolve false
				return

	defer.promise

VPN::getIp = (callback) ->
	defer = Q.defer()
	self = this
	request "http://curlmyip.com/", (error, response, body) ->
		if not error and response.statusCode is 200
			self.ip = body.trim()
			defer.resolve self.ip
		else
			defer.reject error
		return

	defer.promise

VPN::install = ->
	self = this
	if process.platform is "darwin"
		@installRunAs().then(self.installMac).then(self.downloadConfig).then ->

			# we told pt we have vpn enabled..
			App.advsettings.set "vpn", true
			return

	else if process.platform is "linux"
		@installLinux().then(self.downloadConfig).then ->

			# ok we are almost done !

			# we told pt we have vpn enabled..
			App.advsettings.set "vpn", true
			return

	else if process.platform is "win32"
		@installRunAs().then(self.downloadConfig).then(self.installWin).then ->

			# ok we are almost done !

			# we told pt we have vpn enabled..
			App.advsettings.set "vpn", true
			return



#
VPN::installRunAs = ->

	# make sure path doesn't exist (for update)
	try
		fs.rmdirSync path.resolve(process.cwd(), "node_modules", "runas")	if fs.existsSync(path.resolve(process.cwd(), "node_modules", "runas"))
	catch e
		console.log e

	# we get our arch & platform
	arch = (if process.arch is "ia32" then "x86" else process.arch)
	platform = (if process.platform is "darwin" then "mac" else process.platform)
	self = this

	# force x86 as we only have nw 32bit
	# for mac & windows
	arch = "x86"	if platform is "mac" or platform is "win32"
	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/runas-" + platform + "-" + arch + ".tar.gz"
	downloadTarballAndExtract(tarball).then (temp) ->

		# we install the runas module
		console.log "runas imported"
		copyToLocation path.resolve(process.cwd(), "node_modules", "runas"), temp


VPN::downloadConfig = ->

	# make sure path exist
	try
		fs.mkdirSync getInstallPath()	unless fs.existsSync(getInstallPath())
	catch e
		console.log e
	configFile = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn.conf"
	downloadFileToLocation(configFile, "config.ovpn").then (temp) ->
		copyToLocation path.resolve(getInstallPath(), "openvpn.conf"), temp


VPN::installMac = ->
	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-mac.tar.gz"
	downloadTarballAndExtract(tarball).then (temp) ->

		# we install openvpn
		copyToLocation getInstallPath(), temp


VPN::installWin = ->
	arch = (if process.arch is "ia32" then "x86" else process.arch)
	installFile = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-windows-" + arch + ".exe"
	downloadFileToLocation(installFile, "setup.exe").then (temp) ->

		# we launch the setup with admin privilege silently
		# and we install openvpn in %USERPROFILE%\.openvpn
		try
			return runas(temp, [
				"/S"
				"SELECT_SERVICE=1"
				"/SELECT_SHORTCUTS=0"
				"/SELECT_OPENVPNGUI=0"
				"/D=" + getInstallPath()
			])
		catch e
			console.log e
			return false
		return


VPN::installLinux = ->

	# we get our arch & platform
	arch = (if process.arch is "ia32" then "x86" else process.arch)
	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-linux-" + arch + ".tar.gz"
	downloadTarballAndExtract(tarball).then (temp) ->

		# we install openvpn
		copyToLocation getInstallPath(), temp


VPN::disconnect = ->
	defer = Q.defer()
	self = this

	# need to run first..
	defer.resolve()	unless @running
	if process.platform is "win32"
		root = undefined
		if process.env.SystemDrive
			root = process.env.SystemDrive
		else
			root = process.env.SystemRoot.split(path.sep)[0]

			# fallback if we dont get it
			root = "C:"	if root.length is 0
		root = path.join(root, "Windows", "System32", "net.exe")

		# we need to stop the service
		runas root, [
			"stop"
			"OpenVPNService"
		]
		self.getIp()
		self.running = false
		console.log "openvpn stoped"
		defer.resolve()
	else
		getPid().then (pid) ->
			if pid
				runas "kill", [
					"-9"
					pid
				],
					admin: true


				# we'll delete our pid file
				try
					fs.unlinkSync path.join(getInstallPath(), "vpnht.pid")
				catch e
					console.log e
				self.getIp()
				self.running = false
				console.log "openvpn stoped"
				defer.resolve()
			else
				console.log "no pid found"
				self.running = false
				defer.reject "no_pid_found"
			return

	defer.promise

VPN::connect = ->
	defer = Q.defer()
	self = this

	# we are writing a temp auth file
	fs = require("fs")
	tempPath = temp.mkdirSync("popcorntime-vpnht")
	tempPath = path.join(tempPath, "o1")
	fs.writeFile tempPath, App.settings.vpnUsername + "\n" + App.settings.vpnPassword, (err) ->
		if err
			defer.reject err
		else

			# ok we have our auth file
			# now we need to make sure we have our openvpn.conf
			vpnConfig = path.resolve(getInstallPath(), "openvpn.conf")
			if fs.existsSync(vpnConfig)
				try
					openvpn = path.resolve(getInstallPath(), "openvpn")
					args = [

					]
					if process.platform is "linux"

						# in linux we need to add the --dev tun0
						args = [

						]

					# execption for windows openvpn path
					if process.platform is "win32"

						# we copy our openvpn.conf for the windows service
						newConfig = path.resolve(getInstallPath(), "config", "openvpn.ovpn")
						copy vpnConfig, newConfig, (err) ->
							console.log err	if err
							fs.appendFile newConfig, "\r\nauth-user-pass " + tempPath.replace(/\\/g, "\\\\"), (err) ->
								root = undefined
								if process.env.SystemDrive
									root = process.env.SystemDrive
								else
									root = process.env.SystemRoot.split(path.sep)[0]

									# fallback if we dont get it
									root = "C:"	if root.length is 0
								root = path.join(root, "Windows", "System32", "net.exe")
								if fs.existsSync(root)
									runas root, [

									]
									self.running = true
									console.log "openvpn launched"

									# set our current ip
									self.getIp()
									defer.resolve()
								else
									defer.reject "openvpn_command_not_found"
								return

							return

					else
						if fs.existsSync(openvpn)

							# we'll delete our pid file to
							# prevent any connexion error
							try
								fs.unlinkSync path.join(getInstallPath(), "vpnht.pid")	if fs.existsSync(path.join(getInstallPath(), "vpnht.pid"))
							catch e
								console.log e
							if runas(openvpn, args,
								admin: true
							) isnt 0

								# we didnt got success but process run anyways..
								console.log "something wrong"
								self.running = true
								self.getIp()
								defer.resolve()
							else
								self.running = true
								console.log "openvpn launched"

								# set our current ip
								self.getIp()
								defer.resolve()
				catch e
					defer.reject "error_runas"
			else
				defer.reject "openvpn_config_not_found"
		return

	defer.promise

downloadTarballAndExtract = (url) ->
	defer = Q.defer()
	tempPath = temp.mkdirSync("popcorntime-openvpn-")
	stream = tar.Extract(path: tempPath)
	stream.on "end", ->
		defer.resolve tempPath
		return

	stream.on "error", ->
		defer.resolve false
		return

	createReadStream
		url: url
	, (requestStream) ->
		requestStream.pipe(zlib.createGunzip()).pipe stream
		return

	defer.promise

downloadFileToLocation = (url, name) ->
	defer = Q.defer()
	tempPath = temp.mkdirSync("popcorntime-openvpn-")
	tempPath = path.join(tempPath, name)
	stream = fs.createWriteStream(tempPath)
	stream.on "finish", ->
		defer.resolve tempPath
		return

	stream.on "error", ->
		defer.resolve false
		return

	createReadStream
		url: url
	, (requestStream) ->
		requestStream.pipe stream
		return

	defer.promise

createReadStream = (requestOptions, callback) ->
	callback request.get(requestOptions)


# move file
copyToLocation = (targetFilename, fromDirectory) ->
	defer = Q.defer()
	mv fromDirectory, targetFilename, (err) ->
		defer.resolve err
		return

	defer.promise


# copy instead of mv (so we keep original)
copy = (source, target, cb) ->
	done = (err) ->
		unless cbCalled
			cb err
			cbCalled = true
		return
	cbCalled = false
	rd = fs.createReadStream(source)
	rd.on "error", (err) ->
		done err
		return

	wr = fs.createWriteStream(target)
	wr.on "error", (err) ->
		done err
		return

	wr.on "close", (ex) ->
		done()
		return

	rd.pipe wr
	return

getPid = ->
	defer = Q.defer()
	fs.readFile path.join(getInstallPath(), "vpnht.pid"), "utf8", (err, data) ->
		if err
			defer.resolve false
		else
			defer.resolve data.trim()
		return

	defer.promise

getInstallPath = ->
	switch process.platform
		when "darwin", "linux"
			return path.join(process.env.HOME, ".openvpn")
		when "win32"
			return path.join(process.env.USERPROFILE, ".openvpn")
		else
			return false

haveBinaries = ->
	switch process.platform
		when "darwin", "linux"
			return fs.existsSync(path.resolve(getInstallPath(), "openvpn"))
		when "win32"
			return fs.existsSync(path.resolve(getInstallPath(), "bin", "openvpn.exe"))
		else
			return false

runas = (cmd, args, options) ->
	runasApp = undefined
	if process.platform is "linux"
		password = prompt("ATTENTION! We need admin acccess to run this command.\n\nYour password is not saved\n\nEnter sudo password : ", "")	unless password
		exec = require("child_process").exec
		child = exec("sudo " + cmd + " " + args.join(" "), (error, stdout, stderr) ->
			if error isnt null
				console.log "exec error: " + error
				1
		)
		child.stdin.write password
		0
	else if process.platform is "win32"
		try
			runasApp = require("runas")
			runasApp cmd + " " + args.join(" "), (error) ->
				1	if error isnt null

			return 0
		catch e
			console.log e
			return 1
	else
		try
			runasApp = require("runas")
			return runasApp(cmd, args, options)
		catch e
			console.log e
			return 1
	return
