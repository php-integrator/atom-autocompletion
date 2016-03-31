Utility = require './Utility'
AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides autocompletion for class names (also after the new keyword and in use statements).
##
class ClassProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    regex: /(?:^|[^\$:>\w])((?:(?:namespace|new|use)\s+)?\\?[a-zA-Z_][a-zA-Z0-9_]*(?:\\[a-zA-Z_][a-zA-Z0-9_]*)*\\?)$/

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
        successHandler = (classes) =>
            @pendingPromise = null

            return unless classes

            @listCache = classes

            return @listCache

        failureHandler = () =>
            @pendingPromise = null

            return []

        if not @pendingPromise?
            @pendingPromise = @service.getClassList(true).then(successHandler, failureHandler)

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

        successHandler = (classes) =>
            return [] unless classes

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @addSuggestions(classes, prefix.trim(), insertParameterList)

        failureHandler = () =>
            # Just return no results.
            return []

        return @fetchResults().then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  classes
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters for constructors or not.
     *
     * @return {array}
    ###
    addSuggestions: (classes, prefix, insertParameterList = true) ->
        # Get rid of the leading "new" or "use" keyword
        isUse = false
        hasLeadingSlash = false
        isInstantiation = false

        if prefix.indexOf("new ") != -1
            isInstantiation = true
            prefix = prefix.replace /new /, ''

        else if prefix.indexOf("use ") != -1
            isUse = true
            prefix = prefix.replace /use /, ''

        else if prefix.indexOf("namespace ") != -1
            isUse = true
            prefix = prefix.replace /namespace /, ''

        if prefix.indexOf("\\") == 0
            hasLeadingSlash = true
            prefix = prefix.substring(1, prefix.length)

        suggestions = []

        for name, element of classes when element.name
            prefixParts = prefix.split('\\')
            suggestionParts = element.name.split('\\')

            # We try to add an import that has only as many parts of the namespace as needed, for example, if the user
            # types 'Foo\Class' and confirms the suggestion 'My\Foo\Class', we add an import for 'My\Foo' and leave the
            # user's code at 'Foo\Class' as a relative import. We only add the full 'My\Foo\Class' if the user were to
            # type just 'Class' and then select 'My\Foo\Class' (i.e. we remove as many segments from the suggestion
            # as the user already has in his code).
            nameToUseParts = suggestionParts.slice(-1)
            nameToImportParts = suggestionParts

            if prefixParts.length > 1
                partsToSlice = (prefixParts.length - 1)

                nameToUseParts = suggestionParts.slice(-partsToSlice - 1)
                nameToImportParts = suggestionParts.slice(0, -partsToSlice)

            nameToUse = nameToUseParts.join('\\')
            nameToImport = nameToImportParts.join('\\')

            if hasLeadingSlash
                # Don't try to add use statements for class names that the user wants to make absolute by adding a
                # leading slash.
                nameToImport = null

            suggestionData =
                text               : nameToUse
                type               : if element.isTrait then 'mixin' else 'class'
                description        : if element.isBuiltin then 'Built-in PHP structural element.' else element.descriptions.short
                leftLabel          : element.type
                descriptionMoreURL : if element.isBuiltin then @config.get('php_documentation_base_urls').classes + element.name else null
                className          : if element.isDeprecated then 'php-integrator-autocomplete-plus-strike' else ''
                replacementPrefix  : prefix
                displayText        : element.name

            if isUse
                # Use statements always get the full class name as completion.
                suggestionData.text = element.name
                suggestionData.type = 'import'

            else
                if isInstantiation and (element.type != 'class' or element.isAbstract)
                    continue # Not possible to instantiate these.

                suggestionData.data =
                    nameToImport: nameToImport

            suggestions.push suggestionData

        return suggestions

    ###*
     * Called when the user confirms an autocompletion suggestion.
     *
     * @param {TextEditor} editor
     * @param {Position}   triggerPosition
     * @param {object}     suggestion
    ###
    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
        return unless suggestion.data?.nameToImport

        currentClassName = @service.determineCurrentClassName(editor, triggerPosition)

        if currentClassName
            currentNamespaceParts = currentClassName.split('\\')
            currentNamespaceParts.pop()

            currentNamespace = currentNamespaceParts.join('\\')

            if suggestion.data.nameToImport.indexOf(currentNamespace) == 0
                 nameToImportRelativeToNamespace = suggestion.displayText.substr(currentNamespace.length + 1)

                 # If a user is in A\B and wants to import A\B\C\D, we don't need to add a use statement if he is typing
                 # C\D, as it will be relative, but we will need to add one when he typed just D as it won't be
                 # relative.
                 return if nameToImportRelativeToNamespace.split('\\').length == suggestion.text.split('\\').length

        editor.transact () =>
            linesAdded = Utility.addUseClass(editor, suggestion.data.nameToImport, @config.get('insertNewlinesForUseStatements'))
