fuzzaldrin = require 'fuzzaldrin'

Utility = require './Utility'
AbstractProvider = require './AbstractProvider'

module.exports =

##*
# Provides autocompletion for class names (also after the new keyword and in use statements).
##
class ClassProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * "new" keyword or word starting with capital letter
    ###
    regex: /((?:new|use)?(?:[^a-z0-9_])\\?(?:[A-Z][a-zA-Z_\\]*)+)/g

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix.length

        classes = @service.getClassList(true).then (classes) =>
            return [] unless classes

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            return @findSuggestionsForPrefix(classes, prefix.trim(), insertParameterList)

    ###*
     * Returns suggestions available matching the given prefix
     *
     * @param {array}  classes
     * @param {string} prefix
     * @param {bool}   insertParameterList Whether to insert a list of parameters for constructors or not.
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (classes, prefix, insertParameterList = true) ->
        # Get rid of the leading "new" or "use" keyword
        instantiation = false
        use = false

        if prefix.indexOf("new \\") != -1
            instantiation = true
            prefix = prefix.replace /new \\/, ''

        else if prefix.indexOf("new ") != -1
            instantiation = true
            prefix = prefix.replace /new /, ''

        else if prefix.indexOf("use ") != -1
            use = true
            prefix = prefix.replace /use /, ''

        if prefix.indexOf("\\") == 0
            prefix = prefix.substring(1, prefix.length)

        flatList = (obj for name,obj of classes)

        matches = fuzzaldrin.filter(flatList, prefix, key: 'name')

        suggestions = []

        for match in matches when match.name
            # Just print classes with constructors with "new"
            if instantiation and match.methods and ("__construct" of match.methods)
                args = match.methods.__construct.args

                suggestions.push
                    text: match.name,
                    type: 'class',
                    className: if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                    snippet: if insertParameterList then @getFunctionSnippet(match.name, args) else null
                    displayText: @getFunctionSignature(match.name, args)
                    data:
                        kind: 'instantiation',
                        prefix: prefix,
                        replacementPrefix: prefix

            else if use
                suggestions.push
                    text: match.name,
                    type: 'class',
                    prefix: prefix,
                    className: if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                    replacementPrefix: prefix,
                    data:
                        kind: 'use'

            # Not instantiation => not printing constructor params
            else
                suggestions.push
                    text: match.name,
                    type: 'class',
                    className: if match.args.deprecated then 'php-integrator-autocomplete-plus-strike' else ''
                    data:
                        kind: 'static',
                        prefix: prefix,
                        replacementPrefix: prefix

        return suggestions

    ###*
     * Adds the missing use if needed
     * @param {TextEditor} editor
     * @param {Position}   triggerPosition
     * @param {object}     suggestion
    ###
    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
        return unless suggestion.data?.kind

        if suggestion.data.kind == 'instantiation' or suggestion.data.kind == 'static'
            editor.transact () =>
                linesAdded = Utility.addUseClass(editor, suggestion.text, @config.get('insertNewlinesForUseStatements'))

                # Removes namespace from classname
                if linesAdded != null
                    name = suggestion.text
                    splits = name.split('\\')

                    nameLength = splits[splits.length-1].length
                    startColumn = triggerPosition.column - suggestion.data.prefix.length
                    row = triggerPosition.row + linesAdded

                    if suggestion.data.kind == 'instantiation'
                        endColumn = startColumn + name.length - nameLength - splits.length + 1

                    else
                        endColumn = startColumn + name.length - nameLength

                    editor.setTextInBufferRange([
                        [row, startColumn],
                        [row, endColumn] # Because when selected there's not \ (why?)
                    ], "")
