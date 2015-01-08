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

VPN::isRunning = () ->
	defer = Q.defer()
	self = this
	getStatus (data) ->
		if data
			defer.resolve data.connected

	defer.promise

VPN::connect = (protocol) ->
	self = this
	monitorStatus()
	# pptp -- supported by windows only actually
	if protocol == 'pptp'

		# we look if we have pptp installed
		pptpEnabled = window.App.advsettings.get("vpnPPTP")
		if pptpEnabled
			return @connectPPTP()
		else
			console.log('install')
			@installPPTP().then () ->
				console.log('connect')
				self.connectPPTP()
	else

		# we look if we have openvpn installed
		ovpnEnabled = window.App.advsettings.get("vpnOVPN")
		if ovpnEnabled and haveBinariesOpenVPN()
			return @connectOpenVPN()
		else
			console.log('install')
			@installOpenVPN().then () ->
				console.log('connect')
				self.connectOpenVPN()

VPN::disconnect = () ->
	console.log(@running)
	console.log(@protocol)
	self = this
	if @running and @protocol == 'pptp'
		monitorStatus('d')
		return self.disconnectPPTP()

	else if @running and @protocol == 'openvpn'
		monitorStatus('d')
		return self.disconnectOpenVPN()

	else
		# we try all !
		self.disconnectOpenVPN().then () ->
			self.disconnectPPTP().then () ->
				monitorStatus('d')
