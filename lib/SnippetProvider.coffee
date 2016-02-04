AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides useful snippets.
##
class SnippetProvider extends AbstractProvider
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

        return @addSuggestions(@fetchTagList(), prefix.trim())

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {array}  tagList
     * @param {string} prefix
     *
     * @return {array}
    ###
    addSuggestions: (tagList, prefix) ->
        suggestions = []

        for tag in tagList
            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                type                : 'snippet',
                description         : 'PHP snippet.'
                snippet             : tag.snippet
                displayText         : tag.name
                replacementPrefix   : prefix

        return suggestions

    ###*
     * Retrieves a list of known docblock tags.
     *
     * @return {array}
    ###
    fetchTagList: () ->
        return [
            # Useful snippets for keywords:
            {name : 'catch',           snippet : 'catch (${1:\Exception} ${2:\$e}) {\n    ${3:// TODO: Handling.}\n}'},

            {name : '__halt_compiler', snippet : '__halt_compiler()'},
            {name : 'array',           snippet : 'array($1)$0'},
            {name : 'die',             snippet : 'die($1)$0'},
            {name : 'empty',           snippet : 'empty(${1:expression})$0'},
            {name : 'eval',            snippet : 'eval(${1:expression})$0'},
            {name : 'exit',            snippet : 'exit($1)$0'},
            {name : 'isset',           snippet : 'isset(${1:${2:\$array}[\'${3:value}\']})$0'},
            {name : 'list',            snippet : 'list(${1:\$a, \$b})$0'},
            {name : 'unset',           snippet : 'unset(${1:${2:\$array}[\'${3:value}\']})$0'}
        ]
