ClassProvider = require "./ClassProvider"

module.exports =

##*
# Provides autocompletion for docblock annotations.
##
class DocblockAnnotationProvider extends ClassProvider
    ###*
     * @inheritdoc
     *
     * These can only appear in docblocks. Including the space in the capturing group ensures that autocompletion will
     * start right after putting down an asterisk instead of when the tag symbol '@' is entered.
    ###
    regex: /^\s*(?:\/\*)?\*\s@(\\?[a-zA-Z_]?[a-zA-Z0-9_]*(?:\\[a-zA-Z_][a-zA-Z0-9_]*)*\\?)$/

    ###*
     * @inheritdoc
    ###
    scopeSelector: '.comment.block.documentation.phpdoc.php'

    ###*
     * @inheritdoc
    ###
    disableForScopeSelector: ''

    ###*
     * @inheritdoc
    ###
    handleSuccessfulCacheRefresh: (classes) ->
        filteredClasses = {}

        for name, element of classes
            if element.isAnnotation
                filteredClasses[name] = element

        super(filteredClasses)

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        matches = @getPrefixMatchesByRegex(editor, bufferPosition, @regex)

        return [] unless matches?

        successHandler = (classes) =>
            return [] unless classes

            return @getClassSuggestions(classes, matches)

        failureHandler = () =>
            # Just return no results.
            return []

        return @fetchResults().then(successHandler, failureHandler)
