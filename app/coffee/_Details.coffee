class Details

    @open = ->
        hideAll()
        $('.details').show()

        # put username
        $('.usernameLabel').html(window.vpn.user.username)

        # we check protol
        if process.platform is "darwin"
            protocols = ['openvpn']
        else if process.platform is "win32"
            protocols = ['openvpn', 'pptp']
        else if process.platform is "linux"
            protocols = ['openvpn']

        $('#protocol').empty()
        $('#servers').empty()

        _.each protocols, (protocol) ->
            $('#protocol').append('<option value="'+protocol+'">'+protocol.toUpperCase()+'</option>');

        #servers = _.first window.vpn.servers
        #_.each servers, (server) ->
        #    $('#servers').append('<option value="'+server+'">'+server.toUpperCase()+'</option>');
