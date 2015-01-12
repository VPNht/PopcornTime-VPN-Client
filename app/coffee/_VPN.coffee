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
	hideAll()
	self = this
	window.connectionTimeout = false
	$('.connecting').show()

	monitorStatus()
	window.Bugsnag.metaData = vpn:
		protocol: protocol

	# pptp -- supported by windows only actually
	if protocol == 'pptp'

		# we look if we have pptp installed
		pptpEnabled = window.App.advsettings.get("vpnPPTP")
		if pptpEnabled
			Debug.info('Client', 'Connecting PPTP')
			return @connectPPTP()
		else
			Debug.info('Client', 'Installing PPTP')
			@installPPTP().then () ->
				Debug.info('Client', 'Connecting PPTP')
				self.connectPPTP()
	else

		# we look if we have openvpn installed
		ovpnEnabled = window.App.advsettings.get("vpnOVPN")
		if ovpnEnabled and haveBinariesOpenVPN() and haveBinariesTAP()
			Debug.info('Client', 'Connecting OpenVPN')
			return @connectOpenVPN()
		else
			Debug.info('Client', 'Installing OpenVPN')
			@installOpenVPN().then () ->
				Debug.info('Client', 'Connecting OpenVPN')
				self.connectOpenVPN()

VPN::disconnect = () ->
	hideAll()
	$('.loading').show()

	self = this
	if @running and @protocol == 'pptp'
		monitorStatus('d')
		Debug.info('Client', 'Disconnecting PPTP')
		return self.disconnectPPTP()

	else if @running and @protocol == 'openvpn'
		monitorStatus('d')
		Debug.info('Client', 'Disconnecting OpenVPN')
		return self.disconnectOpenVPN()

	else
		# we try all !
		Debug.info('Client', 'Disconnecting PPTP & OpenVPN')
		self.disconnectOpenVPN().then () ->
			self.disconnectPPTP().then () ->
				monitorStatus('d')
