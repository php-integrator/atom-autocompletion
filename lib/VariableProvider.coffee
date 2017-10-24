{Point} = require 'atom'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for local variable names.
##
class VariableProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * Variables are allowed inside double quoted strings (see also
     * {@link https://secure.php.net/manual/en/language.types.string.php#language.types.string.parsing}).
    ###
    disableForScopeSelector: '.source.php .comment, .source.php .string.quoted.single'

    ###*
     * @inheritdoc
    ###
    regex: /((?:\\?[a-zA-Z_][a-zA-Z0-9_]*(?:\\[a-zA-Z_][a-zA-Z0-9_]*)*\s+)?\$(?:[a-zA-Z_][a-zA-Z0-9_]*)?)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        # Don't complete local variable names if we found a type hint.
        newBufferPosition = new Point(bufferPosition.row, bufferPosition.column - prefix.length)

        return [] if editor.scopeDescriptorForBufferPosition(newBufferPosition).getScopeChain().indexOf('.support.class') != -1

        parts = prefix.split(/\s+/)

        typeHint = parts[0]
        prefix   = parts[1]

        if not prefix?
            prefix = typeHint

        prefix   = prefix.trim()

        offset = editor.getBuffer().characterIndexForPosition(bufferPosition)

        # Don't include the variable we're completing.
        offset -= prefix.length

        text = editor.getBuffer().getText()

        # Strip out the text currently being completed, as when the user is typing a variable name, a syntax error may
        # ensue. The base service will start ignoring parts of the file if that happens, which causes inconsistent
        # results.
        text = text.substr(0, offset) + text.substr(offset + prefix.length)

        successHandler = (variables) =>
            return @addSuggestions(variables, prefix)

        failureHandler = () =>
            return []

        return @service.getAvailableVariablesByOffset(editor.getPath(), text, offset).then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {array}  variables
     * @param {string} prefix
     *
     * @return array
    ###
    addSuggestions: (variables, prefix) ->
        suggestions = []

        for name, variable of variables
            type = null

            # Just show the last part of a class name with a namespace.
            if variable.type
                parts = variable.type.split('\\')
                type = parts.pop()

            suggestions.push
                type              : 'variable'
                text              : variable.name
                leftLabel         : type
                replacementPrefix : prefix

        return suggestions
