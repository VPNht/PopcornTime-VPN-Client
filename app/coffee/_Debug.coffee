class Debug

    @error = (errorName, errorMsg, errorLog) ->
        errorLog = errorLog || false
        if errorLog
            console.log("[ERROR] " + errorMsg, errorLog)
        else
            console.log("[ERROR] > " + errorMsg)

        Bugsnag.notify(errorName, errorMsg, errorLog, "error")

    @warning = (warningMsg, warningLog) ->
        warningLog = warningLog || false
        if warningLog
            console.log("[WARN] " + warningMsg, warningLog)
        else
            console.log("[WARN] > " + warningMsg)

        Bugsnag.notify(warningName, warningMsg, warningLog, "warning")

    @info = (infoName, infoMsg, infoLog) ->
        infoLog = infoLog || false
        if infoLog
            console.log("[INFO] " + infoMsg, infoLog)
        else
            console.log("[INFO] > " + infoMsg)

        Bugsnag.notify(infoName, infoMsg, infoLog, "info")
