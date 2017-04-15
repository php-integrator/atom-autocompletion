{Point} = require 'atom'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for magic constants.
##
class MagicConstantProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * "new" keyword or word starting with capital letter
    ###
    regex: /(__?(?:[A-Z]+_?_?)?)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        return @addSuggestions(prefix.trim())

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {string} prefix
     *
     * @return {array}
    ###
    addSuggestions: (prefix) ->
        suggestions = []

        constants = {
            # See also https://secure.php.net/manual/en/reserved.keywords.php.
            '__CLASS__'     : 'string',
            '__DIR__'       : 'string',
            '__FILE__'      : 'string',
            '__FUNCTION__'  : 'string',
            '__LINE__'      : 'int',
            '__METHOD__'    : 'string',
            '__NAMESPACE__' : 'string',
            '__TRAIT__'     : 'string'
        }

        for name, type of constants
            suggestions.push
                type              : 'constant'
                text              : name
                leftLabel         : type
                replacementPrefix : prefix

        return suggestions
