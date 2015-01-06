_ = require('underscore')
class Details

    @open = () ->
        $('.login').hide()
        $('.status').hide()
        $('.details').show()
        $('.usernameLabel').html(window.vpn.user.username)

        # we check protol
        if process.platform is "darwin"
            protocols = ['openvpn', 'l2tp']
        else if process.platform is "win32"
            protocols = ['openvpn', 'pptp']
        else if process.platform is "linux"
            protocols = ['openvpn']

        _.each protocols, (protocol) ->
            $('#protocol').append('<option value="'+protocol+'">'+protocol.toUpperCase()+'</option>');

        servers = _.first window.vpn.servers
        _.each servers, (server) ->
            console.log(server)
            $('#servers').append('<option value="'+server+'">'+server.toUpperCase()+'</option>');
