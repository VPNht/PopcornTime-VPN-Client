hideAll = ->
    $('.login').hide()
    $('.status').hide()
    $('.installScript').hide()
    $('.details').hide()
    $('.connecting').hide()
    $('.loading').hide()

autoLogin = ->
    # we check if we have existing login and we auto login
    if window.App and window.App.settings.vpnUsername and window.App.settings.vpnPassword
        $('#username').val(window.App.settings.vpnUsername)
        $('#password').val(window.App.settings.vpnPassword)
        Auth.login()

# when we create a new timer it increment
# the id returned
# so when we pass it we remove all timer
# under it as well to prevent multiple
# timer running
clearTimer = (maxId) ->
    i = 0
    while i < maxId
        clearTimeout i
        i += 1

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
