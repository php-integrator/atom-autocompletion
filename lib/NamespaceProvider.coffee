AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for namespaces after the namespace keyword.
##
class NamespaceProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    regex: /namespace\s+(\\?[a-zA-Z_][a-zA-Z0-9_]*(?:\\[a-zA-Z_][a-zA-Z0-9_]*)*\\?)?$/

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

        @timeoutHandle = setTimeout ( =>
            @timeoutHandle = null
            @refreshCache()
        ), @config.get('largeListRefreshTimeout')

    ###*
     * Refreshes the internal cache. Returns a promise that resolves with the cache once it has been refreshed.
     *
     * @return {Promise}
    ###
    refreshCache: () ->
        successHandler = (namespaces) =>
            @pendingPromise = null

            return unless namespaces

            @listCache = namespaces

            return @listCache

        failureHandler = () =>
            @pendingPromise = null

            return []

        if not @pendingPromise?
            @pendingPromise = @service.getNamespaceList().then(successHandler, failureHandler)

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

        successHandler = (namespaces) =>
            return [] unless namespaces

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @addSuggestions(namespaces, prefix.trim(), insertParameterList)

        failureHandler = () =>
            return []

        return @fetchResults().then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  namespaces
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters or not.
     *
     * @return {array}
    ###
    addSuggestions: (namespaces, prefix, insertParameterList = true) ->
        suggestions = []

        for namespace in namespaces
            continue if namespace.namespace.length == 0

            fqcnWithoutLeadingSlash = namespace.namespace

            if fqcnWithoutLeadingSlash[0] == '\\'
                fqcnWithoutLeadingSlash = fqcnWithoutLeadingSlash.substring(1)

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                text               : fqcnWithoutLeadingSlash
                type               : 'import'
                leftLabel          : 'namespace'
                displayText        : fqcnWithoutLeadingSlash

        return suggestions
