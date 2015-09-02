module.exports = (grunt) ->

    require('load-grunt-tasks')(grunt)

    grunt.initConfig

        useminPrepare:
            html: "app/index.html"
            options:
                dest: "dist"

        usemin:
            html: ["dist/index.html"]

        copy:
            html:
                src: 'app/index.html'
                dest: "dist/index.html"
            robots:
                src: 'app/robots.txt'
                dest: "dist/robots.txt"
            app:
                cwd: 'app/'
                expand: true
                src: ["img/**", "fonts/**"]
                dest: "dist/"
            misc:
                cwd: 'misc/'
                expand: true
                src: ["linux","bin/*","config/*"]
                dest: "dist/"

        connect:
            server:
                options:
                    port: 8080
                    base: './dist'

        watch:
            coffee:
                files: ['app/coffee/*']
                tasks: ['build']

        coffee:
            compileBare:
                options:
                    bare: true
                files:
                    'app/js/app.js': ['app/coffee/app.coffee', 'app/coffee/_*.coffee']

        filerev:
            css:
                src: "dist/css/app.css"
            js:
                src: "dist/js/app.js"

        filerev_replace:
            views:
                options:
                    assets_root: '/'
                src: 'dist/index.html'

        htmlmin:
            dist:
                options:
                    removeComments: true
                    collapseWhitespace: true
                files:
                    'dist/index.html': 'dist/index.html'

    grunt.registerTask 'default', ['coffee']
    grunt.registerTask 'develop', ['build', 'connect', 'watch']
    grunt.registerTask 'build', ['default', 'useminPrepare', 'copy', 'concat', 'uglify', 'cssmin', 'filerev', 'filerev_replace','usemin','htmlmin']
