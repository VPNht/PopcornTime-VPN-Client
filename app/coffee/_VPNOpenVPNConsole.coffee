net = require("net")

class OpenVPNManagement

    @send = (msg, callback) ->
        client = new net.Socket()

        client.setTimeout 2000

        client.connect 1337, "127.0.0.1", ->
            client.write msg + "\n"

        client.on "timeout", ->
            client.destroy()
            callback true, false

        client.on "error", ->
            client.destroy()
            callback true, false

        client.on "data", (data) ->
            client.destroy()
            # return only the line #3 with his content
            lines = data.toString().split(/\r\n|\n|\r/)
            callback false, data.toString().split(/\r\n|\n|\r/)[lines.length-2]

    @getLog = (callback) ->
        client = new net.Socket()

        client.setTimeout 2000

        client.connect 1337, "127.0.0.1", ->
            client.write 'log 20' + "\n"

        client.on "timeout", ->
            client.destroy()
            callback true, false

        client.on "error", ->
            client.destroy()
            callback true, false

        client.on "data", (data) ->
            client.destroy()
            # return only the line #3 with his content
            lines = data.toString().split(/\r\n|\n|\r/)
            callback false, lines
