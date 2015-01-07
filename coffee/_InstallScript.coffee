_ = require('underscore')
class InstallScript

    @open = () ->
        $('.login').hide()
        $('.status').hide()
        $('.details').hide()
        $('.installScript').show()
        
