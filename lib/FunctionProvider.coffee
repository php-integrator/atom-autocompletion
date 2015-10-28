fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for internal PHP functions.
##
class FunctionProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    fetchSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # not preceded by a > (arrow operator), a $ (variable start), ...
        @regex = /(?:(?:^|[^\w\$_\>]))([a-z_]+)(?![\w\$_\>])/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        functions = @service.getGlobalFunctions()

        return unless functions

        characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
        insertParameterList = if characterAfterPrefix == '(' then false else true

        suggestions = @findSuggestionsForPrefix(functions, prefix.trim(), insertParameterList)
        return unless suggestions.length
        return suggestions

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  functions
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters or not.
     *
     * @return {Array}
    ###
    findSuggestionsForPrefix: (functions, prefix, insertParameterList = true) ->
        flatList = (obj for name,obj of functions)

        matches = fuzzaldrin.filter(flatList, prefix, key: 'name')

        suggestions = []

        for match in matches
            suggestions.push
                text: match,
                type: 'function',
                description: 'Built-in PHP function.' # Needed or the 'More' button won't show up.
                descriptionMoreURL: @config.get('php_documentation_base_urls').functions + match.name
                className: if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                snippet: if insertParameterList then @getFunctionSnippet(match.name, match.args) else null
                displayText: @getFunctionSignature(match.name, match.args)
                replacementPrefix: prefix

        return suggestions
