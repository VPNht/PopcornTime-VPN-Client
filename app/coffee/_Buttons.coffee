$ ->
    $('#username,#password').keypress (e) ->
        Auth.login() if e.which is 13

    $('#login').on 'click', ->
        Auth.login()

    $('#logoutBtn').on 'click', ->
        Auth.logout()

    $('#connectBtn').on 'click', ->
        App.VPN.connect($('#protocol').val());

    $('#cancelBtn,#disconnectBtn').on 'click', ->
        App.VPN.disconnect();

    $('#createAccount').on 'click', ->
        gui.Shell.openExternal('https://vpn.ht/popcorntime');

    $('#helpBtn,#helpdeskBtn').on 'click', ->
        gui.Shell.openExternal('https://vpnht.zendesk.com/hc/en-us');

    $('#forgotPassword').on 'click', ->
        gui.Shell.openExternal('https://vpn.ht/forgot');

    $('#showDetail').on 'click', ->
        Details.open()
