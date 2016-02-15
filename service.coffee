
window.service = service = {}

alight.filters.encodeDataUri = (value, exp, scope) ->
    if not value
        return ''
    encodeURIComponent(value)

alight.filters.formatBytes = (value, expression, scope) ->
    return if typeof value isnt "number"
    bytes = value
    sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    return '0 Byte' if bytes is 0
    i = parseInt(Math.floor(Math.log(bytes) / Math.log(1000)))
    Math.round(bytes / Math.pow(1000, i), 2) + ' ' + sizes[i]

service.get = (url, isJson) ->
    new Promise (resolve, reject) ->
        alight.f$.ajax
            url: url
            success: (data) ->
                if isJson
                    if typeof data is 'string'
                        data = JSON.parse data
                resolve data
            error: reject


service.loadList = (version) ->
    version ?= 'master'
    url = "https://raw.githubusercontent.com/lega911/angular-light/#{version}/source.json"
    service.get url, true

service.getTags = ->
    service.get('https://api.github.com/repos/lega911/angular-light/git/refs/tags', true).then (data) ->
        result = ['master']
        for i in data
            ver = i.ref.split('/').pop()
            if ver[0] isnt 'v'
                continue
            value = ver.slice(1).split('.').map(Number).reduce (a, b) => a*1000+b
            if value >= 12015
                result.push ver
        return result


service.buildHeader = (url) ->
    service.get(url).then (data) =>
        version =
            version: data.match(/version.*?\'([^\']+)\'/)[1]
            date: data.match(/date.*?\'([^\']+)\'/)[1]

        source = [
            "/**"
            "  * Angular Light " + version.version + ", (c) 2016 Oleg Nechaev"
            "  * Released under the MIT License."
            "  * " + version.date + " http://angularlight.org/"
            "  * custom build: " + document.location.href
            "  */"
        ].join('\n') + "\n"

        source: source
        version: version


service.loadBody = (list) ->
    loading = []
    for url in list
        loading.push service.get url

    Promise.all(loading).then (data) =>
        result = ''
        for source, i in data
            name = list[i]

            if name.split('.').pop() is 'coffee'
                source = CoffeeScript.compile(source, {bare: true})
            result += source
        result
