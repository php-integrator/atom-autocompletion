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
        return [] unless prefix != null

        successHandler = (functions) =>
            return [] unless functions

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @addSuggestions(functions, prefix.trim(), insertParameterList)

        failureHandler = () =>
            return []

        return @service.getGlobalFunctions(true).then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  functions
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters or not.
     *
     * @return {array}
    ###
    addSuggestions: (functions, prefix, insertParameterList = true) ->
        suggestions = []

        for name, func of functions
            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                text               : func.name
                type               : 'function'
                snippet            : if insertParameterList then @getFunctionSnippet(func.name, func) else null
                displayText        : func.name
                replacementPrefix  : prefix
                leftLabel          : @getClassShortName(func.return?.type)
                rightLabelHTML     : @getSuggestionRightLabel(name, func)
                description        : if func.isBuiltin then 'Built-in PHP function.' else func.descriptions.short
                descriptionMoreURL : if func.isBuiltin then @config.get('php_documentation_base_urls').functions + func.name else null
                className          : 'php-integrator-autocomplete-plus-suggestion' + if func.isDeprecated then ' php-integrator-autocomplete-plus-strike' else ''

        return suggestions
