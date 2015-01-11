class Debug

    @error = (errorName, errorMsg, errorLog) ->
        errorLog = errorLog || {}
        console.log(errorName + ' ' + errorMsg, errorLog)
        Bugsnag.notify(errorName, errorMsg, errorLog, "error")

    @warning = (warningName, warningMsg, warningLog) ->
        warningLog = warningLog || {}
        console.log(warningName + ' ' + warningMsg, warningLog)
        Bugsnag.notify(warningName, warningMsg, warningLog, "warning")

    @info = (infoName, infoMsg, infoLog) ->
        infoLog = infoLog || {}
        console.log(infoName + ' ' + infoMsg, infoLog)
        Bugsnag.notify(infoName, infoMsg, infoLog, "info")
