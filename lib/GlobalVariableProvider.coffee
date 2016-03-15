VariableProvider = require "./VariableProvider"

module.exports =

##*
# Provides autocompletion for global variable names (such as superglobals).
##
class GlobalVariableProvider extends VariableProvider
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
