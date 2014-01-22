emblemLib = Npm.require('emblem')
emblemLib.handlebarsVariant = handlebars = Npm.require('handlebars')
path = Npm.require('path')

# Adpated from Meteor's html_scanner (v0.7.0.1 @d30bb79498c),
class EmblemScanner
  # Scan a template file for head, body, and template
  # tags and extract their contents.
  #
  # This is a primitive, regex-based scanner.  It scans
  # top-level tags, which are allowed to have attributes,
  # and ignores top-level HTML comments.
  constructor: ->
    @results =
      head : ""
      body : ""
      js   : ""

  scan: (contents, @sourcePath) ->
    contents = ("\n" + contents)
      .replace(/\r/g, "\n")
      .replace(/\n\/.*/g, "\n") # Strip top level comments
    [ignore, sections...] = contents.split(/\n\b/)
    @_scanSection(section) for section in sections
    @results

  _scanSection: (section) ->
    [_m, tagName, attributeStr, tagContents] = section.match(/^(\w+)(.*)[\n\r]([\s\S]*)$/)
    tagName = tagName.toLowerCase()
    tagAttribs = @_parseAttributes(attributeStr)
    # act on the tag
    @_handleTag tagName, tagAttribs, tagContents

  _parseAttributes: (attributeStr) ->
    tagAttribs = {} # bare name -> value dict
    rTagPart = /^\s*((([a-zA-Z0-9:_-]+)\s*=\s*(["'])(.*?)\4)?)/
    loop
      [matched, attrToken, _, attrKey, _, attrValue] = attr = rTagPart.exec(attributeStr)
      attributeStr = attributeStr.substring(attr.index + matched.length);
      return tagAttribs unless attrToken

      # XXX we don't HTML unescape the attribute value
      # (e.g. to allow "abcd&quot;efg") or protect against
      # collisions with methods of tagAttribs (e.g. for
      # a property named toString)
      attrValue = attrValue.match(/^\s*([\s\S]*?)\s*$/)[1] # trim
      tagAttribs[attrKey] = attrValue

  _handleTag: (tag, attribs, contents) ->
    # do we have 1 or more attribs?
    hasAttribs = false
    for k of attribs
      if attribs.hasOwnProperty(k)
        hasAttribs = true
        break
    if tag is "head"
      @_throwParseError "Attributes on <head> not supported"  if hasAttribs
      @results.head += handlebars.compile(@_parseToHBast(contents))()
      return

    # <body> or <template>
    ast = @_parseToJSONast(contents)
    code = "Package.handlebars.Handlebars.json_ast_to_func(" + JSON.stringify(ast) + ")"
    if tag is "template"
      name = attribs.name
      @_throwParseError "Template has no 'name' attribute"  unless name
      @results.js += "Template.__define__(" + JSON.stringify(name) + "," + code + ");\n"
    else
      # <body>
      @_throwParseError "Attributes on <body> not supported"  if hasAttribs
      @results.js += "Meteor.startup(function(){" + "document.body.appendChild(Spark.render(" + "Template.__define__(null," + code + ")));});"

  _parseToJSONast: (contents) ->
    Handlebars.ast_to_json_ast(@_parseToHBast(contents))

  _parseToHBast: (contents) ->
    try
      emblemLib.parse(contents)
    catch e
      if e instanceof Handlebars.ParseError
        if typeof (e.line) is "number"
          @_throwParseError e.message, e.line - 1

        # No line number available from Handlebars parser, so
        # generate the parse error at the <template> tag itself
        else
          @_throwParseError "error in template: " + e.message
      else
        throw e

  _throwParseError: (msg) ->
    throw new EmblemScanner.ParserError(
      msg or "bad formatting in Emblem template"
      @sourcePath
    )

EmblemScanner.scan = (contents, sourcePath) ->
  new EmblemScanner().scan(contents, sourcePath)

class EmblemScanner.ParserError
  initialize: (@message, @sourcePath, @line = 0) ->

emblemCompiler = (compileStep) ->
  # XXX use archinfo rather than rolling our own

  # XXX might be nice to throw an error here, but then we'd have to
  # make it so that packages.js ignores html files that appear in
  # the server directories in an app tree.. or, it might be nice to
  # make html files actually work on the server (against jsdom or
  # something)
  return  unless compileStep.arch.match(/^browser(\.|$)/)

  # XXX the way we deal with encodings here is sloppy .. should get
  # religion on that
  contents = compileStep.read().toString("utf8")
  try
    results = EmblemScanner.scan(contents, compileStep.inputPath)
  catch e
   if e instanceof EmblemScanner.ParseError
     compileStep.error e
     return
   else
     throw e
  if results.head
    compileStep.appendDocument
      section: "head"
      data: results.head

  if results.body
    compileStep.appendDocument
      section: "body"
      data: results.body

  if results.js
    path_part = path.dirname(compileStep.inputPath)
    path_part = ""  if path_part is "."
    path_part = path_part + path.sep  if path_part.length and path_part isnt path.sep
    ext = path.extname(compileStep.inputPath)
    basename = path.basename(compileStep.inputPath, ext)

    # XXX generate a source map
    compileStep.addJavaScript
      path: path.join(path_part, "template." + basename + ".js")
      sourcePath: compileStep.inputPath
      data: results.js

Plugin?.registerSourceHandler "emblem", emblemCompiler
