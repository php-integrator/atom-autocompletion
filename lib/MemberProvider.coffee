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
                    # Constants are only available when statically accessed (actually not entirely correct, they will
                    # work in a non-static context as well, but it's not good practice).
                    return false if mustBeStatic and not element.isStatic

                    if objectBeingCompleted != '$this'
                        # Explicitly checking for '$this' allows files that are being require-d inside classes to define
                        # a type override annotation for $this and still be able to access private and protected members
                        # there.
                        return false if element.isPrivate and element.declaringClass.name != currentClass
                        return false if element.isProtected and element.declaringClass.name != currentClass and element.declaringClass.name not in currentClassParents

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
        suggestions = []

        processList = (list) =>
            for name, member of list
                if filterCallback and not filterCallback(member)
                    continue

                # Ensure we don't get very long return types by just showing the last part.
                snippet = null
                displayText = member.name
                returnValue = @getClassShortName(member.return?.type)

                if member.name of classInfo.methods
                    type = 'method'
                    snippet = if insertParameterList then @getFunctionSnippet(member.name, member) else null
                    displayText = @getFunctionSignature(member.name, member)

                else if member.name of classInfo.properties
                    type = 'property'

                else
                    type = 'constant'

                # Determine the short name of the location where this member is defined.
                declaringStructureShortName = null

                if member.declaringStructure.name
                    declaringStructure = null

                    if member.override
                        declaringStructure = member.override.declaringStructure

                    else if member.implementation
                        declaringStructure = member.implementation.declaringStructure

                    else
                        declaringStructure = member.declaringStructure

                    declaringStructureShortName = @getClassShortName(declaringStructure.name)

                suggestions.push
                    text        : member.name,
                    type        : type
                    snippet     : snippet
                    displayText : displayText
                    leftLabel   : returnValue
                    rightLabel  : declaringStructureShortName
                    description : if member.descriptions.short? then member.descriptions.short else ''
                    className   : if member.isDeprecated then 'php-integrator-autocomplete-plus-strike' else ''

        processList(classInfo.methods)
        processList(classInfo.constants)
        processList(classInfo.properties)

        return suggestions
