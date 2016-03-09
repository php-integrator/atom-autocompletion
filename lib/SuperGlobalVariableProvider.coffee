VariableProvider = require "./VariableProvider"

module.exports =

##*
# Provides autocompletion for superglobal variable names.
##
class SuperGlobalVariableProvider extends VariableProvider
    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        return @addSuggestions(prefix)

    ###*
     * @inheritdoc
    ###
    addSuggestions: (prefix) ->
        suggestions = []

        variables = [
            '$GLOBALS',
            '$_SERVER',
            '$_GET',
            '$_POST',
            '$_FILES',
            '$_COOKIE',
            '$_SESSION',
            '$_REQUEST',
            '$_ENV'
        ]

        for variable in variables
            suggestions.push
                type              : 'variable'
                text              : variable
                leftLabel         : 'array'
                replacementPrefix : prefix

        return suggestions
