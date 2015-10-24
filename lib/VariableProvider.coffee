fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for local variable names.
##
class VariableProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # "new" keyword or word starting with capital letter
        @regex = /(\$[a-zA-Z_]*)/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        variables = @service.getAvailableVariables(editor, bufferPosition)
        return unless variables.length

        suggestions = @findSuggestionsForPrefix(variables, prefix.trim())
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  variables
     * @param {string} prefix
     *
     * @return array
    ###
    findSuggestionsForPrefix: (variables, prefix) ->
        words = fuzzaldrin.filter(variables, prefix)

        suggestions = []

        for word in words
            suggestions.push
                text: word,
                type: 'variable',
                replacementPrefix: prefix

        return suggestions
