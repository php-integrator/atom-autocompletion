AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for internal PHP functions.
##
class FunctionProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * These can appear pretty much everywhere, but not in variable names or as class members. Note that functions can
     * also appear inside namespaces, hence the middle part.
    ###
    regex: /(?:^|[^\$:>\w])((?:[a-zA-Z_][a-zA-Z0-9_]*\\)*[a-z_]+)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix.length

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
        suggestions = []

        for name, func of functions
            returnValue = @getClassShortName(func.return?.type)

            # If we don't escape the slashes, they will not show up in the autocompleted text. See also
            # https://github.com/atom/autocomplete-plus/issues/577
            nameToUseEscaped = func.name.replace('\\', '\\\\')

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                text                : func,
                type                : 'function',
                description         : if func.isBuiltin then 'Built-in PHP function.' else func.descriptions.short
                leftLabel           : returnValue
                descriptionMoreURL  : if func.isBuiltin then @config.get('php_documentation_base_urls').functions + func.name else null
                className           : if func.isDeprecated then 'php-integrator-autocomplete-plus-strike' else ''
                snippet             : if insertParameterList then @getFunctionSnippet(nameToUseEscaped, func) else null
                displayText         : @getFunctionSignature(func.name, func)
                replacementPrefix   : prefix

        return suggestions
