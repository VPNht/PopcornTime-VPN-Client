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
	$('.connecting').show()

	self = this
	window.connectionTimeout = false
	window.Bugsnag.metaData = vpn:
		protocol: protocol

	# pptp -- supported by windows only actually
	if protocol == 'pptp'

		# we look if we have pptp installed
		pptpEnabled = window.App.advsettings.get("vpnPPTP")
		if pptpEnabled
			Debug.info('Client', 'Connecting PPTP')
			return @connectPPTP().then () ->
				monitorStatus()
		else
			Debug.info('Client', 'Installing PPTP')
			@installPPTP().then () ->
				Debug.info('Client', 'Connecting PPTP')
				self.connectPPTP().then () ->
					monitorStatus()
	else

		# we look if we have openvpn installed
		ovpnEnabled = window.App.advsettings.get("vpnOVPN")
		if ovpnEnabled and haveBinariesOpenVPN()
			Debug.info('Client', 'Connecting OpenVPN')
			return @connectOpenVPN().then () ->
				monitorStatus()
		else
			Debug.info('Client', 'Installing OpenVPN')
			@installOpenVPN().then () ->
				Debug.info('Client', 'Connecting OpenVPN')
				self.connectOpenVPN().then () ->
					monitorStatus()

VPN::disconnect = () ->
	hideAll()
	$('.loading').show()

	self = this
	window.pendingCallback = false
	window.connectionTimeout = false
	clearTimeout window.connectionTimeoutTimer if window.connectionTimeoutTimer
	clearTimeout window.timerMonitorConsole if window.timerMonitorConsole
	clearTimeout window.timerMonitor if window.timerMonitor

	if @running and @protocol == 'pptp'
		Debug.info('Client', 'Disconnecting PPTP')
		return self.disconnectPPTP().then () ->
			disconnectUser()

	else if @running and @protocol == 'openvpn'
		Debug.info('Client', 'Disconnecting OpenVPN')
		return self.disconnectOpenVPN().then () ->
			disconnectUser()

	else
		# we try all !
		canConnectOpenVPN()
            .then (err) ->
				if err != false
					Debug.info('Client', 'Disconnecting OpenVPN')
					self.disconnectOpenVPN().then () ->
						disconnectUser()
				else
					Debug.info('Client', 'Disconnecting PPTP')
					self.disconnectPPTP().then () ->
						disconnectUser()

			.catch (err) ->
				Debug.info('Client', 'Disconnecting PPTP')
				self.disconnectPPTP().then () ->
					disconnectUser()
