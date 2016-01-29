class main
	core: {fqueryIE8: {}}
	files: {}
	download: 
		fileSize: 0
		uncompressed:
			fileSize: 0
			content: ""
		compressed:
			fileSize: 0
			content: ""
	status: 0
	preCheckedItems: []

	constructor: ->
		window.main = this

		@preCheckedItems = document.location.hash.substr(1).split('-')

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
			do (item, list) =>
				alight.f$.ajax
					url: item.download_url
					success: (data) =>
						setTimeout =>
							extensions = /(\.coffee|\.js)$/
							item.ext = item.name.match(extensions)?[1]
							item.blankName = item.name.replace(extensions, '')

							if item.ext is '.coffee'
								item.content = CoffeeScript.compile(data, {bare: true})
								item.compiled_size = item.content.length
								item.ext = '.js'
							else if item.ext is '.js'
								item.content = data
								item.compiled_size = item.size
								if list is 'js'
									@core[item.blankName] = item

							if list in ['filter', 'directive'] or (list is 'js' and item.blankName is 'fqueryIE8')
								if @preCheckedItems.length is 0 or item.blankName in @preCheckedItems
									item.checked = true
								else
									item.checked = false
							else
								item.checked = true

							@$scan()
						, 200

	trackSize: ->
		@$watch 'files', =>
			size = 0
			hash = []
			for key,list of @files
				for item in list when item.type is 'file' and item.checked
					size += item.compiled_size
					if key in ['filter', 'directive'] or (key is 'js' and item.blankName is 'fqueryIE8')
						hash.push item.blankName
			@download.uncompressed.fileSize = size
			document.location.hash = '#' + hash.join('-')
		, deep: true

	onToggleAll: (exp) ->
		list = @$getValue(exp)
		for item in list when item.type is 'file'
			item.checked = !item.checked
		@$scan()

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

		res = res.replace('{{{version}}}', version.version)
		res = [
			"/**"
			"  * Angular Light " + version.version + ", (c) 2016 Oleg Nechaev"
			"  * Released under the MIT License."
			"  * " + version.date + " http://angularlight.org/"
			"  * custom build: " + document.location.href
			"  */"
		].join('\n') + "\n" + res

		@download.uncompressed.content = res
		@download.uncompressed.fileSize = res.length

	onMinify: ->
		version =
			version: @core.version.content.match(/version.*?\'([^\']+)\'/)[1]
			date: @core.version.content.match(/date.*?\'([^\']+)\'/)[1]

		callback = (res) =>
			res = res.replace('{{{version}}}', version.version)
			res = "// Angular Light " + version.version + " (c) 2016 Oleg Nechaev, MIT License. " + version.date + ", http://angularlight.org/, custom build: " + document.location.href + "\n" + res
			@download.compressed.content = res
			@download.compressed.fileSize = res.length

		res = @uglify(@download.uncompressed.content, callback)

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


alight.filters.encodeDataUri = (value, exp, scope) ->
	encodeURIComponent(value)

alight.filters.formatBytes = (value, expression, scope) ->
	return if typeof value isnt "number"
	bytes = value
	sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
	return '0 Byte' if bytes is 0
	i = parseInt(Math.floor(Math.log(bytes) / Math.log(1000)))
	Math.round(bytes / Math.pow(1000, i), 2) + ' ' + sizes[i]

alight.bootstrap "#app"
