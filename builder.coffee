class main
    constructor: ->
        window.main = this
        @.versions = []
        @.version = 'master'
        @.files = {}
        @.status = 0

        service.getTags().then (data) =>
            @.versions = data
            @.$scan()

        @.reloadList()

    toggleVersion: (version) ->
        @.version = version
        @.reloadList()

    reloadList: ->
        service.loadList(@.version).then (data) =>
            @.files = {}
            order = 1
            for file in data
                file.order = order++
                partName = @.getPart file
                @.files[partName] ?= []
                @.files[partName].push file
            @.$scan()

    getPart: (file) ->
        d = file.file.split '/'
        if d.length < 2
            return 'core'
        if d[0] is 'directive'
            return d[0]
        if d[0] is 'filter'
            return d[0]
        'core'

    toggleAll: (part) ->
        for file in part
            file.checked = not file.checked

    toggleBuild: (tag) ->
        clear = (flag) =>
            for partName, part of @.files
                for file in part
                    file.checked = flag
            return

        clear false
        if not tag
            return
        if tag is 'all'
            clear true
            return

        tags = {
            core:
                core: true
            basis:
                core: true
                basis: true
            full:
                core: true
                basis: true
                full: true
            compatibility:
                core: true
                basis: true
                full: true
                compatibility: true
        }[tag]

        for partName, part of @.files
            for file in part
                for i in file.tag
                    if tags[i]
                        file.checked = true

    compile: ->
        list = []
        for partName, part of @.files
            for file in part
                if not file.checked
                    continue
                list.push file
        list.sort (a, b) ->
            a.order - b.order

        buildUrl = (file) =>
            "https://raw.githubusercontent.com/lega911/angular-light/#{@.version}/src/#{file}"

        loadHeader = service.buildHeader buildUrl 'js/version.js'

        fileList = list.map (f) -> buildUrl f.file

        service.loadBody(fileList).then (source) =>
            loadHeader.then (header) =>
                @.fileBody = source.replace('{{{version}}}', header.version.version)
                @.fileHeader = header.source

                @.resultFile = @.fileHeader + @.fileBody
                @.$scan()

    minify: ->
        @.uglify @.fileBody, (result) =>
            @.minifiedFile = @.fileHeader + result

    uglify: (code, callback) ->
        scope = @
        scope.status = 0
        setTimeout ->
            toplevel = UglifyJS.parse(code)
            scope.status = 15
            scope.$scan()
            setTimeout ->
                toplevel.figure_out_scope()
                scope.status = 30
                scope.$scan()
                setTimeout ->
                    compressor = UglifyJS.Compressor()
                    compressedAst = toplevel.transform(compressor)
                    scope.status = 60
                    scope.$scan()
                    setTimeout ->
                        compressedAst.figure_out_scope()
                        scope.status = 80
                        scope.$scan()
                        setTimeout ->
                            callback compressedAst.print_to_string()
                            scope.status = 100
                            scope.$scan()
                        , 250
                    , 250
                , 250
            , 250
        , 250


alight.ctrl.main = main

alight.bootstrap "#app"
