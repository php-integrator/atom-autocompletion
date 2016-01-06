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
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        scopeDescriptorChain = scopeDescriptor.getScopeChain()

        if scopeDescriptorChain.indexOf('.keyword.operator.class') != -1 or scopeDescriptorChain.indexOf('meta.function-call.object') != -1
            return [] # Don't show anything when autocompleting class members.

        # We always show all suggestions when there is no prefix.
        if prefix.trim() != ''
            tmpPrefix = @getPrefix(editor, bufferPosition)
            return [] unless tmpPrefix != null

        return @service.getGlobalConstants(true).then (constants) =>
            return [] unless constants

            return @findSuggestionsForPrefix(constants, prefix.trim())

    ###*
     * Returns suggestions available matching the given prefix
     *
     * @param {array}  constants
     * @param {string} prefix
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (constants, prefix) ->
        suggestions = []

        for name, constant of constants
            suggestions.push
                text        : constant.name,
                type        : 'constant',
                description : if constant.isBuiltin then 'Built-in PHP constant.' else 'Global PHP constant.'

        return suggestions
