# async function to run with admin privilege
# linux: use gksu or kdesu
# win: use custom vbs
# mac: use osascript

# example: runas 'ls', ['-la']

runas = (cmd, args, callback) ->
	exec = require("child_process").exec
	if process.platform is "linux"
		child = exec "which gksu", (error, stdout, stderr) ->
			console.log(stdout)
			console.log(stderr)
			console.log(error)
			if stdout
				cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " " + cmd + " " + args.join(" ")
				console.log cmd
				child = exec cmd, (error, stdout, stderr) ->
					return callback(false) if error isnt null
					return callback(true)
			else
				child = exec "which kdesu", (error, stdout, stderr) ->
					if stdout
						cmd = stdout.replace(/(\r\n|\n|\r)/gm,"") + " " + cmd + " " + args.join(" ")
						child = exec cmd, (error, stdout, stderr) ->
							return callback(false) if error isnt null
							return callback(true)
					else
						# user need to run our script
						InstallScript.open()
						return callback(false)

	else if process.platform is "win32"
		cmd = path.join(getInstallPathOpenVPN(), 'runas.cmd') + " " + cmd + " " + args.join(" ")
		child = exec cmd, (error, stdout, stderr) ->
			return callback(false) if error isnt null
			return callback(true)
	else
		cmd = "osascript -e 'do shell script \"" + cmd + " " + args.join(" ") + " \" with administrator privileges'"
		child = exec cmd, (error, stdout, stderr) ->
			console.log(stdout)
			return callback(false) if error isnt null
			return callback(true)
