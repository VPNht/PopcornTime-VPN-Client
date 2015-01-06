# mac install openvpn
VPN::installOpenVPN = ->
    switch process.platform

        when "darwin"
        	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-mac.tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation getInstallPathOpenVPN(), temp

        when "linux"
        	arch = (if process.arch is "ia32" then "x86" else process.arch)
        	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-linux-" + arch + ".tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation getInstallPath(), temp

        when "win32"
        	tarball = "https://s3-eu-west-1.amazonaws.com/vpnht/openvpn-mac.tar.gz"
        	downloadTarballAndExtract(tarball).then (temp) ->

        		# we install openvpn
        		copyToLocation getInstallPathOpenVPN(), temp

# helper to get vpn install path
getInstallPathOpenVPN = ->
	switch process.platform
		when "darwin", "linux"
			return path.join(process.env.HOME, ".openvpn")
		when "win32"
			return path.join(process.env.USERPROFILE, ".openvpn")
		else
			return false
