Config = require './Config'

module.exports =

##*
# Config that retrieves its settings from Atom's config.
##
class AtomConfig extends Config
    ###*
     * The name of the package to use when searching for settings.
    ###
    packageName: null

    ###*
     * @inheritdoc
    ###
    constructor: (@packageName) ->
        super()

        @attachListeners()

    ###*
     * @inheritdoc
    ###
    load: () ->
        @set('disableBuiltinAutocompletion', atom.config.get("#{@packageName}.disableBuiltinAutocompletion"))
        @set('insertNewlinesForUseStatements', atom.config.get("#{@packageName}.insertNewlinesForUseStatements"))
        @set('enablePhpunitAnnotationTags', atom.config.get("#{@packageName}.enablePhpunitAnnotationTags"))
        @set('automaticallyAddUseStatements', atom.config.get("#{@packageName}.automaticallyAddUseStatements"))
        @set('largeListRefreshTimeout', atom.config.get("#{@packageName}.largeListRefreshTimeout"))
        @set('largeListRefreshTimeoutJitter', atom.config.get("#{@packageName}.largeListRefreshTimeoutJitter"))

    ###*
     * Attaches listeners to listen to Atom configuration changes.
    ###
    attachListeners: () ->
        atom.config.onDidChange "#{@packageName}.disableBuiltinAutocompletion", () =>
            @set('disableBuiltinAutocompletion', atom.config.get("#{@packageName}.disableBuiltinAutocompletion"))

        atom.config.onDidChange "#{@packageName}.insertNewlinesForUseStatements", () =>
            @set('insertNewlinesForUseStatements', atom.config.get("#{@packageName}.insertNewlinesForUseStatements"))

        atom.config.onDidChange "#{@packageName}.enablePhpunitAnnotationTags", () =>
            @set('enablePhpunitAnnotationTags', atom.config.get("#{@packageName}.enablePhpunitAnnotationTags"))

        atom.config.onDidChange "#{@packageName}.automaticallyAddUseStatements", () =>
            @set('automaticallyAddUseStatements', atom.config.get("#{@packageName}.automaticallyAddUseStatements"))

        atom.config.onDidChange "#{@packageName}.largeListRefreshTimeout", () =>
            @set('largeListRefreshTimeout', atom.config.get("#{@packageName}.largeListRefreshTimeout"))

        atom.config.onDidChange "#{@packageName}.largeListRefreshTimeoutJitter", () =>
            @set('largeListRefreshTimeoutJitter', atom.config.get("#{@packageName}.largeListRefreshTimeoutJitter"))
