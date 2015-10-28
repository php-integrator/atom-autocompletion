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

        return unless constants

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
        flatList = (obj for name,obj of constants)

        matches = fuzzaldrin.filter(flatList, prefix, key: 'name')

        suggestions = []

        for match in matches
            suggestions.push
                text: match.name,
                type: 'constant',
                description: 'Built-in PHP constant.'

        return suggestions
