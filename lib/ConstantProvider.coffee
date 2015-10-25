fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for internal PHP constants.
##
class ConstantProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # not preceded by a > (arrow operator), a $ (variable start), ...
        @regex = /(?:(?:^|[^\w\$_\>]))([A-Z_]+)(?![\w\$_\>])/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        constants = @service.getGlobalConstants()

        return unless constants.names?

        suggestions = @findSuggestionsForPrefix(constants, prefix.trim())
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix
     *
     * @param {array}  constants
     * @param {string} prefix
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (constants, prefix) ->
        words = fuzzaldrin.filter constants.names, prefix

        suggestions = []

        for word in words
            for element in constants.values[word]
                suggestions.push
                    text: word,
                    type: 'constant',
                    description: 'Built-in PHP constant.'

        return suggestions
