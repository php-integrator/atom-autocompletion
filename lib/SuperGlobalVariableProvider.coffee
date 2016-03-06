VariableProvider = require "./VariableProvider"

module.exports =

##*
# Provides autocompletion for superglobal variable names.
##
class SuperGlobalVariableProvider extends VariableProvider
    ###*
     * @inheritdoc
    ###
    addSuggestions: (variables, prefix) ->
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
