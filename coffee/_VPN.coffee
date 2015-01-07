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
	if haveBinariesOpenVPN()

		# we'll fallback to check if it's been installed
		# form the app ?
		installed = window.App.advsettings.get("vpn")
		if installed
			return true
		else
			return false
	false

VPN::isDisabled = ->

	#disabled on demand
	disabled = window.App.advsettings.get("vpnDisabledPerm")
	if disabled
		true
	else
		false

VPN::isRunning = (checkOnStart) ->
	defer = Q.defer()
	self = this
	checkOnStart = checkOnStart or false
	if @isInstalled()
		getStatus (data) ->
			if data
				defer.resolve data.connected

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

runas = (cmd, args, options) ->
	exec = require("child_process").exec
	if process.platform is "linux"
		child = exec "which gksu", (error, stdout, stderr) ->

		if stdout
			cmd = stdout + " " + cmd + " " + args.join(" ")
			child = exec cmd, (error, stdout, stderr) ->
				1 if error isnt null
				0
		else
			child = exec "which kdesu", (error, stdout, stderr) ->
				if stdout
					cmd = stdout + " " + cmd + " " + args.join(" ")
					child = exec cmd, (error, stdout, stderr) ->
						1 if error isnt null
						0
				else
					# user need to run our script
					InstallScript.open()
		
	else if process.platform is "win32"
		cmd = path.join(getInstallPathOpenVPN(), 'bin', 'runas.cmd') + " " + cmd + " " + args.join(" ")
		child = exec cmd, (error, stdout, stderr) ->
			1 if error isnt null
			0
	else
		cmd = "osascript -e 'do shell script \"" + cmd + " " + args.join(" ") + " \" with administrator privileges'"
		child = exec cmd, (error, stdout, stderr) ->
			1 if error isnt null
			0