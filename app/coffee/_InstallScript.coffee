class InstallScript

    @open = ->
        Debug.info('InstallScript', 'Show Install Script')
        hideAll()
        $('.installScript').show()
