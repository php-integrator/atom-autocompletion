fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for internal PHP functions.
##
class FunctionProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * These can appear pretty much everywhere, but not in variable names or as class members. We just use the regex
     * here to validate, but not to filter out the correct bits, as autocomplete-plus already seems to do this
     * correctly.
    ###
    regex: /(?:^|[^\$:>\w])([a-z_]+)/g

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        tmpPrefix = @getPrefix(editor, bufferPosition)
        return [] unless tmpPrefix.length

        return @service.getGlobalFunctions(true).then (functions) =>
            return [] unless functions

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @findSuggestionsForPrefix(functions, prefix.trim(), insertParameterList)

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  functions
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters or not.
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (functions, prefix, insertParameterList = true) ->
        flatList = (obj for name,obj of functions)

        matches = fuzzaldrin.filter(flatList, prefix, key: 'name')

        suggestions = []

        for match in matches
            returnValue = @getClassShortName(match.args.return?.type)

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                text                : match,
                type                : 'function',
                description         : if match.isBuiltin then 'Built-in PHP function.' else match.args.descriptions.short
                leftLabel           : returnValue
                descriptionMoreURL  : if match.isBuiltin then @config.get('php_documentation_base_urls').functions + match.name else null
                className           : if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                snippet             : if insertParameterList then @getFunctionSnippet(match.name, match.args) else null
                displayText         : @getFunctionSignature(match.name, match.args)
                replacementPrefix   : prefix

        return suggestions
