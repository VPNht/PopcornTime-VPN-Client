class Debug

    @error = (errorName, errorMsg, errorLog) ->
        errorLog = errorLog || false
        d = new Date()
        dateStr = "["+d.getMinutes()+":"+d.getMilliseconds()+"]"
        if errorLog
            console.log(dateStr + " [ERROR] " + errorMsg, errorLog)
        else
            console.log(dateStr + " [ERROR] > " + errorMsg)

        Bugsnag.notify(errorName, errorMsg, errorLog, "error")

    @warning = (warningMsg, warningLog) ->
        warningLog = warningLog || false
        d = new Date()
        dateStr = "["+d.getMinutes()+":"+d.getMilliseconds()+"]"
        if warningLog
            console.log(dateStr + " [WARN] " + warningMsg, warningLog)
        else
            console.log(dateStr + " [WARN] > " + warningMsg)

        Bugsnag.notify(warningName, warningMsg, warningLog, "warning")

    @info = (infoName, infoMsg, infoLog) ->
        infoLog = infoLog || false
        d = new Date()
        dateStr = "["+d.getMinutes()+":"+d.getMilliseconds()+"]"
        if infoLog
            console.log(dateStr + " [INFO] " + infoMsg, infoLog)
        else
            console.log(dateStr + " [INFO] > " + infoMsg)

        Bugsnag.notify(infoName, infoMsg, infoLog, "info")
