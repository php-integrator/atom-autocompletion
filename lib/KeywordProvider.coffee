AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for keywords.
##
class KeywordProvider extends AbstractProvider
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
     * Returns available suggestions.
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
                text                : tag.name
                type                : 'keyword',
                description         : 'PHP keyword.'
                descriptionMoreURL  : @config.get('php_documentation_base_urls').keywords
                replacementPrefix   : prefix

        return suggestions

    ###*
     * Retrieves a list of known docblock tags.
     *
     * @return {array}
    ###
    fetchTagList: () ->
        return [
            {name : 'self'},
            {name : 'static'},
            {name : 'parent'},

            # From https://secure.php.net/manual/en/reserved.other-reserved-words.php.
            {name : 'int'},
            {name : 'float'},
            {name : 'bool'},
            {name : 'string'},
            {name : 'true'},
            {name : 'false'},
            {name : 'null'},
            {name : 'void'},
            {name : 'iterable'},

            # From https://secure.php.net/manual/en/reserved.keywords.php.
            {name : '__halt_compiler'},
            {name : 'abstract'},
            {name : 'and'},
            {name : 'array'},
            {name : 'as'},
            {name : 'break'},
            {name : 'callable'},
            {name : 'case'},
            {name : 'catch'},
            {name : 'class'},
            {name : 'clone'},
            {name : 'const'},
            {name : 'continue'},
            {name : 'declare'},
            {name : 'default'},
            {name : 'die'},
            {name : 'do'},
            {name : 'echo'},
            {name : 'else'},
            {name : 'elseif'},
            {name : 'empty'},
            {name : 'enddeclare'},
            {name : 'endfor'},
            {name : 'endforeach'},
            {name : 'endif'},
            {name : 'endswitch'},
            {name : 'endwhile'},
            {name : 'eval'},
            {name : 'exit'},
            {name : 'extends'},
            {name : 'final'},
            {name : 'finally'},
            {name : 'for'},
            {name : 'foreach'},
            {name : 'function'},
            {name : 'global'},
            {name : 'goto'},
            {name : 'if'},
            {name : 'implements'},
            {name : 'include'},
            {name : 'include_once'},
            {name : 'instanceof'},
            {name : 'insteadof'},
            {name : 'interface'},
            {name : 'isset'},
            {name : 'list'},
            {name : 'namespace'},
            {name : 'new'},
            {name : 'or'},
            {name : 'print'},
            {name : 'private'},
            {name : 'protected'},
            {name : 'public'},
            {name : 'require'},
            {name : 'require_once'},
            {name : 'return'},
            {name : 'static'},
            {name : 'switch'},
            {name : 'throw'},
            {name : 'trait'},
            {name : 'try'},
            {name : 'unset'},
            {name : 'use'},
            {name : 'var'},
            {name : 'while'},
            {name : 'xor'},
            {name : 'yield'}
        ]
