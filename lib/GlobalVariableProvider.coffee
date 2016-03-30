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

        variables = {
            '$argc'     : 'int',
            '$argv'     : 'array',
            '$GLOBALS'  : 'array',
            '$_SERVER'  : 'array',
            '$_GET'     : 'array',
            '$_POST'    : 'array',
            '$_FILES'   : 'array',
            '$_COOKIE'  : 'array',
            '$_SESSION' : 'array',
            '$_REQUEST' : 'array',
            '$_ENV'     : 'array'
        }

        for variable,type of variables
            suggestions.push
                type              : 'variable'
                text              : variable
                leftLabel         : type
                replacementPrefix : prefix

        return suggestions
