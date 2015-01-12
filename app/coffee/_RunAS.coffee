# function to run with admin privilege
# linux: use gksu or kdesu
# win: use custom vbs
# mac: use osascript

# example: runas 'ls', ['-la']

runas = (cmd, args, callback) ->
	if process.platform is "linux"
		child = exec "which gksu", (error, stdout, stderr) ->
			if stdout
				cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " --description \"VPN.ht\" \"" + cmd + " " + args.join(" ") + "\""
				child = exec cmd, (error, stdout, stderr) ->
					Debug.info('RunAS', 'Run command', {cmd: cmd, error:error, stdout:stdout, stderr:stderr})
					return callback(false) if error isnt null
					return callback(true)
			else
				child = exec "which kdesu", (error, stdout, stderr) ->
					if stdout
						cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " -d -c \"" + cmd + " " + args.join(" ") + "\""
						child = exec cmd, (error, stdout, stderr) ->
							Debug.info('RunAS', 'Run command', {cmd: cmd, error:error, stdout:stdout, stderr:stderr})
							return callback(false) if error isnt null
							return callback(true)
					else
						# user need to run our script
						InstallScript.open()
						return callback(false)

	else if process.platform is "win32"
		cmd = path.join(getInstallPathOpenVPN(), 'runas.cmd') + " " + cmd + " " + args.join(" ")
		child = exec cmd, (error, stdout, stderr) ->
			Debug.info('RunAS', 'Run command', {cmd: cmd, error:error, stdout:stdout, stderr:stderr})
			return callback(false) if error isnt null
			return callback(true)
	else
		cmd = "osascript -e 'do shell script \"" + cmd + " " + args.join(" ") + " \" with administrator privileges'"
		child = exec cmd, (error, stdout, stderr) ->
			Debug.info('RunAS', 'Run command', {cmd: cmd, error:error, stdout:stdout, stderr:stderr})
			return callback(false) if error isnt null
			return callback(true)

spawnas = (cmd, args, callback) ->
	args = args or []

	if process.platform is "linux"
		child = exec "which gksu", (error, stdout, stderr) ->
			if stdout
				cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " --description \"VPN.ht\" \"" + cmd + " " + args.join(" ") + "\""
				Debug.info('SpawnAS', 'Run command', {cmd: cmd})
				child = exec(cmd,
					detached: true
				)
				child.unref()
				return callback(true)

			else
				child = exec "which kdesu", (error, stdout, stderr) ->
					if stdout
						cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " -d -c \"" + cmd + " " + args.join(" ") + "\""
						Debug.info('SpawnAS', 'Run command', {cmd: cmd})
						child = exec(cmd,
							detached: true
						)
						child.unref()
						return callback(true)
					else
						# user need to run our script
						InstallScript.open()
						return callback(false)

	else if process.platform is "win32"
		cmd = "\"" + path.join(getInstallPathOpenVPN(), 'runas.cmd') + "\" \"" + cmd + "\" " + args.join(" ")
		Debug.info('SpawnAS', 'Run command', {cmd: cmd})
		child = exec(cmd,
			detached: true
		)
		child.unref()
		return callback(true)
	else
		cmd = "osascript -e 'do shell script \"" + cmd + " " + args.join(" ") + " \" with administrator privileges'"
		Debug.info('SpawnAS', 'Run command', {cmd: cmd})
		child = exec(cmd,
			detached: true
		)
		child.unref()
		return callback(true)
