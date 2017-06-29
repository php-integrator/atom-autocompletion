AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for global PHP functions.
##
class GlobalFunctionProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * These can appear pretty much everywhere, but not in variable names or as class members. Note that functions can
     * also appear inside namespaces, hence the middle part.
    ###
    regex: /(?:^|[^\$:>\w])((?:[a-zA-Z_][a-zA-Z0-9_]*\\)*[a-zA-Z_]+)$/

    ###*
     # Cache object to help improve responsiveness of autocompletion.
    ###
    listCache: null

    ###*
     # A list of disposables to dispose on deactivation.
    ###
    disposables: null

    ###*
     # Keeps track of a currently pending promise to ensure only one is active at any given time.
    ###
    pendingPromise: null

    ###*
     # Keeps track of a currently pending timeout to ensure only one is active at any given time..
    ###
    timeoutHandle: null

    ###*
     * @inheritdoc
    ###
    activate: (@service) ->
        {CompositeDisposable} = require 'atom'

        @disposables = new CompositeDisposable()

        @disposables.add(@service.onDidFinishIndexing(@onDidFinishIndexing.bind(this)))

    ###*
     * @inheritdoc
    ###
    deactivate: () ->
        if @disposables?
            @disposables.dispose()
            @disposables = null

    ###*
     * Called when reindexing successfully finishes.
     *
     * @param {Object} info
    ###
    onDidFinishIndexing: (info) ->
        # Only reindex a couple of seconds after the last reindex. This prevents constant refreshes being scheduled
        # while the user is still modifying the file. This is acceptable as this provider's data rarely changes and
        # it is fairly expensive to refresh the cache.
        if @timeoutHandle?
            clearTimeout(@timeoutHandle)
            @timeoutHandle = null

        timeoutTime = @config.get('largeListRefreshTimeout')
        timeoutTime += Math.random() * @config.get('largeListRefreshTimeoutJitter')

        @timeoutHandle = setTimeout ( =>
            @timeoutHandle = null
            @refreshCache()
        ), timeoutTime

    ###*
     * Refreshes the internal cache. Returns a promise that resolves with the cache once it has been refreshed.
     *
     * @return {Promise}
    ###
    refreshCache: () ->
        successHandler = (functions) =>
            @pendingPromise = null

            return unless functions

            @listCache = functions

            return @listCache

        failureHandler = () =>
            @pendingPromise = null

            return []

        if not @pendingPromise?
            @pendingPromise = @service.getGlobalFunctions().then(successHandler, failureHandler)

        return @pendingPromise

    ###*
     * Fetches a list of results that can be fed to the addSuggestions method.
     *
     * @return {Promise}
    ###
    fetchResults: () ->
        return new Promise (resolve, reject) =>
            if @listCache?
                resolve(@listCache)
                return

            return @refreshCache()

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        successHandler = (functions) =>
            return [] unless functions

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @addSuggestions(functions, prefix.trim(), insertParameterList)

        failureHandler = () =>
            return []

        return @fetchResults().then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  functions
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters or not.
     *
     * @return {array}
    ###
    addSuggestions: (functions, prefix, insertParameterList = true) ->
        suggestions = []

        for fqcn, func of functions
            shortDescription = ''

            if func.shortDescription? and func.shortDescription.length > 0
                shortDescription = func.shortDescription

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                text               : func.name
                type               : 'function'
                snippet            : if insertParameterList then @getFunctionSnippet(func.name, func) else null
                displayText        : func.name + @getFunctionParameterList(func)
                replacementPrefix  : prefix
                leftLabel          : @getTypeSpecificationFromTypeArray(func.returnTypes)
                rightLabelHTML     : @getSuggestionRightLabel(func)
                description        : shortDescription
                descriptionMoreURL : null
                className          : 'php-integrator-autocomplete-plus-suggestion' + if func.isDeprecated then ' php-integrator-autocomplete-plus-strike' else ''

        return suggestions
