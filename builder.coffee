class main
	core: {fqueryIE8: {}}
	files: {}
	download: 
		fileSize: 0
		uncompressed: {
			fileSize: 0
			content: ""
		}

	constructor: ->
		window.main = this

		baseUrl = 'https://api.github.com/repos/lega911/angular-light/contents/'
		sources = {
			core:      baseUrl + 'src?ref=master'
			js:        baseUrl + 'src/js?ref=master'
			parser:    baseUrl + 'src/parser?ref=master'
			directive: baseUrl + 'src/directive?ref=master'
			filter:    baseUrl + 'src/filter?ref=master'
			text:      baseUrl + 'src/text?ref=master'
		}
		for source,url of sources
			do (source, url) =>
				processStructure = (data) =>
					@files[source] = JSON.parse(data)
					@$scan()
					@fetchFiles(source)					

				alight.f$.ajax
					url: url
					success: processStructure


		@trackSize()

	fetchFiles: (list) ->
		for item in @files[list] when item.type is 'file'
			item.checked = false
			do (item) =>
				alight.f$.ajax
					url: item.download_url
					success: (data) =>
						setTimeout =>
							if item.name.match(/\.coffee$/)
								item.content = CoffeeScript.compile(data, {bare: true})
								item.compiled_size = item.content.length
							else
								item.content = data
								item.compiled_size = item.size
							if item.name.match(/(prefix|fquery|fqueryIE8|postfix|version)\.js$/)
								@core[item.name.replace('.js', '')] = item
							item.checked = true
							@$scan()
						, 200
		
	trackSize: ->
		@$watch 'files', =>
			size = 0
			for key,list of @files
				for item in list when item.type is 'file' and item.checked
					size += item.compiled_size
			@download.fileSize = size
		, deep: true

	onCompile: ->
		@download.uncompressed.content = ""

		res  = @core.prefix.content
		res += @core.fquery.content
		res += @core.fqueryIE8.content if @core.fqueryIE8.checked

		for item in @files.core when item.type is 'file'
			res += item.content
		
		for key,list of @files when key not in ['js', 'core']
			for item in list when item.type is 'file' and item.checked
				res += item.content

		res += @core.postfix.content

		version = 
			version: @core.version.content.match(/version.*?\'([^\']+)\'/)[1]
			date: @core.version.content.match(/date.*?\'([^\']+)\'/)[1]

		res = res.replace(/{{{version}}}/, version.version)
		res = "/**\n * Angular Light " + version.version + "\n * (c) 2015 Oleg Nechaev\n * Released under the MIT License.\n * " + version.date + ", http://angularlight.org/ \n */\n" + res

		@download.uncompressed.content = 'data:application/javascript;charset:utf-8,' + encodeURIComponent(res)
		@download.uncompressed.fileSize = res.length

alight.ctrl.main = main


alight.filters.formatBytes = (value, expression, scope) ->
	return if typeof value isnt "number"
	bytes = value
	sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
	return '0 Byte' if bytes is 0
	i = parseInt(Math.floor(Math.log(bytes) / Math.log(1000)))
	Math.round(bytes / Math.pow(1000, i), 2) + ' ' + sizes[i]

alight.bootstrap "#app"
