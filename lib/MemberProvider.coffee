fuzzaldrin = require 'fuzzaldrin'

AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for members of variables such as after ->, ::.
##
class MemberProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * Member autocompletion is allowed inside double quoted strings (see also
     * {@link https://secure.php.net/manual/en/language.types.string.php#language.types.string.parsing}). Static class
     * name access must always be wrapped as {${Class::staticAccess}}, our autocompletion will also autocomplete without
     * the extra curly brackets, but it's better to have some autocompletion in a few rare erroneous cases than no
     * autocompletion at all in the most used cases.
    ###
    disableForSelector: '.source.php .comment, .source.php .string.quoted.single'

    ###*
     * @inheritdoc
     *
     * Autocompletion for class members, i.e. after a ::, ->, ...
    ###
    regex: /((?:\$?(?:[a-zA-Z0-9_]*)\s*(?:\(.*\))?\s*(?:->|::)\s*)+[a-zA-Z0-9_]*)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix.length

        try
            className = @service.getResultingTypeAt(editor, bufferPosition, true)

        catch error
            return []

        return [] unless className

        # We only autocomplete after splitters, so there must be at least one word, one splitter, and another word
        # (the latter which could be empty).
        elements = prefix.split(/(->|::)/)
        return [] unless elements.length > 2

        return [] if @service.isBasicType(className)

        successHandler = (currentClassInfo) =>
            currentClassParents = []

            if currentClassInfo
                currentClassParents = currentClassInfo.parents

            mustBeStatic = false

            objectBeingCompleted = elements[elements.length - 3].trim();

            if elements[elements.length - 2] == '::' and objectBeingCompleted != 'parent'
                mustBeStatic = true

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            nestedSuccessHandler = (classInfo) =>
                return @findSuggestionsForPrefix(classInfo, elements[elements.length - 1].trim(), (element) =>
                    # See also atom-autocomplete-php ticket #127.
                    return false if mustBeStatic and not element.isStatic

                    if objectBeingCompleted != '$this'
                        # Explicitly checking for '$this' allows files that are being require-d inside classes to define
                        # a type override annotation for $this and still be able to access private and protected members
                        # there.
                        return false if element.isPrivate and element.declaringClass.name != currentClass
                        return false if element.isProtected and element.declaringClass.name != currentClass and element.declaringClass.name not in currentClassParents

                    # Constants are only available when statically accessed.
                    return false if not element.isMethod and not element.isProperty and not mustBeStatic

                    return true
                , insertParameterList)

            nestedFailureHandler = () =>
                return []

            return @service.getClassInfo(className, true).then(nestedSuccessHandler, nestedFailureHandler)

        currentClass = @service.determineFullClassName(editor)

        if not currentClass
            # There is no need to load the current class' information, return results immediately.
            return successHandler(null)

        failureHandler = () =>
            # Just return no results.
            return []

        # We need to fetch information about the current class, do it asynchronously (using promises).
        return @service.getClassInfo(currentClass, true).then(successHandler, failureHandler)

    ###*
     * Returns suggestions available matching the given prefix.
     *
     * @param {Object}   classInfo           Info about the class to show members of.
     * @param {string}   prefix              Prefix to match (may be left empty to list all members).
     * @param {callback} filterCallback      A callback that should return true if the item should be added to the
     *                                       suggestions list.
     * @param {bool}     insertParameterList Whether to insert a list of parameters for methods.
     *
     * @return {array}
    ###
    findSuggestionsForPrefix: (classInfo, prefix, filterCallback, insertParameterList = true) ->
        members = [];

        # Ensure we have one big pool so we can optimally match using fuzzaldrin.
        members.push(obj) for name,obj of classInfo.methods
        members.push(obj) for name,obj of classInfo.constants
        members.push(obj) for name,obj of classInfo.properties

        matches = fuzzaldrin.filter(members, prefix, key: 'name')

        suggestions = []

        for match in matches
            if filterCallback and not filterCallback(match)
                continue

            # Ensure we don't get very long return types by just showing the last part.
            snippet = null
            displayText = match.name
            returnValue = @getClassShortName(match.return?.type)

            if match.isMethod
                type = 'method'
                snippet = if insertParameterList then @getFunctionSnippet(match.name, match) else null
                displayText = @getFunctionSignature(match.name, match)

            else if match.isProperty
                type = 'property'

            else
                type = 'constant'

            # Determine the short name of the location where this member is defined.
            declaringStructureShortName = null

            if match.declaringStructure.name
                declaringStructure = null

                if match.override
                    declaringStructure = match.override.declaringStructure

                else if match.implementation
                    declaringStructure = match.implementation.declaringStructure

                else
                    declaringStructure = match.declaringStructure

                declaringStructureShortName = @getClassShortName(declaringStructure.name)

            suggestions.push
                text        : match.name,
                type        : type
                snippet     : snippet
                displayText : displayText
                leftLabel   : returnValue
                rightLabel  : declaringStructureShortName
                description : if match.descriptions.short? then match.descriptions.short else ''
                className   : if match.deprecated then 'php-integrator-autocomplete-plus-strike' else ''

        return suggestions
