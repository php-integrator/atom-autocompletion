{Point} = require 'atom'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Suggests new variable names after type hints.
##
class TypeHintNewVariableNameProvider extends AbstractProvider
    ###*
     * @inheritdoc
    ###
    regex: /(\\?[a-zA-Z_][a-zA-Z0-9_]*(?:\\[a-zA-Z_][a-zA-Z0-9_]*)*\s+\$?(?:[a-zA-Z_][a-zA-Z0-9_]*)?)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        # Don't complete local variable names if we found something else than a type hint.
        newBufferPosition = new Point(bufferPosition.row, bufferPosition.column - prefix.length)

        return [] if editor.scopeDescriptorForBufferPosition(newBufferPosition).getScopeChain().indexOf('.meta.function.parameters') == -1

        parts = prefix.split(/\s+/)

        typeHint = parts[0].trim()
        prefix   = parts[1].trim()

        return [] if not typeHint

        return @addSuggestions(typeHint, prefix)

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {string} typeHint
     * @param {string} prefix
     *
     * @return {array}
    ###
    addSuggestions: (typeHint, prefix) ->
        suggestions = []

        typeHintParts = typeHint.split('\\')
        shortTypeName = typeHintParts[typeHintParts.length - 1]

        shortTypeNameParts = shortTypeName.split(/([A-Z][^A-Z]+)/).filter (part) ->
            return part and part.length > 0

        # Example type hint: FooBarInterface
        nameSuggestions = []

        # Suggest 'fooBarInterface':
        nameSuggestions.push(shortTypeName[0].toLowerCase() + shortTypeName.substr(1))

        # Suggest 'fooBar':
        if shortTypeNameParts.length > 1
            shortTypeNameParts.pop()

            name = shortTypeNameParts.join('')

            nameSuggestions.push(name[0].toLowerCase() + name.substr(1))

        for name in nameSuggestions
            suggestions.push
                type              : 'variable'
                text              : '$' + name
                leftLabel         : null
                replacementPrefix : prefix
                rightLabel        : 'New variable'

        return suggestions
