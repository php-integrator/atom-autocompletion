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
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        # not preceded by a > (arrow operator), a $ (variable start), ...
        @regex = /(?:(?:^|[^\w\$_\>]))([a-z_]+)(?![\w\$_\>])/g

        prefix = @getPrefix(editor, bufferPosition)
        return unless prefix.length

        functions = @service.getGlobalFunctions()

        return unless functions.names?

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
        words = fuzzaldrin.filter functions.names, prefix

        suggestions = []

        for word in words
            for element in functions.values[word]
                suggestions.push
                    text: word,
                    type: 'function',
                    description: 'Built-in PHP function.' # Needed or the 'More' button won't show up.
                    descriptionMoreURL: @config.get('php_documentation_base_urls').functions + word
                    className: if element.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                    snippet: if insertParameterList then @getFunctionSnippet(word, element.args) else null
                    displayText: @getFunctionSignature(word, element.args)
                    replacementPrefix: prefix

        return suggestions
