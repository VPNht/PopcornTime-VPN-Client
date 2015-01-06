module.exports = (grunt) ->
    grunt.initConfig
        connect:
            server:
                options:
                    port: 8080
                    base: './'

        watch:
            coffee:
                files: ['coffee/*']
                tasks: ['coffee:compileBare']

        coffee:
            compileBare:
                options:
                    bare: true
                files:
                    'js/app.js': ['coffee/app.coffee', 'coffee/_*.coffee']

        uglify:
            target:
                files:
                    'js/app.js': 'js/app.js'

    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-connect'
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-uglify'

    grunt.registerTask 'default', ['coffee']
    grunt.registerTask 'develop', ['default', 'connect', 'watch']
    grunt.registerTask 'build', ['default', 'uglify']
