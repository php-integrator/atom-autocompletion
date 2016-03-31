AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for internal PHP constants.
##
class ConstantProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * These can appear pretty much everywhere, but not in variable names or as class members. We just use the regex
     * here to validate, but not to filter out the correct bits, as autocomplete-plus already seems to do this
     * correctly.
    ###
    regex: /(?:^|[^\$:>\w])([A-Z_]+)$/

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
        ), 5000

    ###*
     * Refreshes the internal cache. Returns a promise that resolves with the cache once it has been refreshed.
     *
     * @return {Promise}
    ###
    refreshCache: () ->
        successHandler = (constants) =>
            @pendingPromise = null

            return unless constants

            @listCache = constants

            return @listCache

        failureHandler = () =>
            @pendingPromise = null

            return []

        if not @pendingPromise?
            @pendingPromise = @service.getGlobalConstants(true).then(successHandler, failureHandler)

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

        tmpPrefix = @getPrefix(editor, bufferPosition)
        return [] unless tmpPrefix != null

        successHandler = (constants) =>
            return [] unless constants

            return @addSuggestions(constants, prefix.trim())

        failureHandler = () =>
            return []

        return @fetchResults().then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  constants
     * @param {string} prefix
     *
     * @return {array}
    ###
    addSuggestions: (constants, prefix) ->
        suggestions = []

        for name, constant of constants
            suggestions.push
                text        : constant.name,
                type        : 'constant',
                description : if constant.isBuiltin then 'Built-in PHP constant.' else 'Global PHP constant.'

        return suggestions
