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
    regex: /((?:\$?(?:[a-zA-Z0-9_]*)\s*(?:\(.*\))?\s*(?:->|::)\s*)+\$?[a-zA-Z0-9_]*)$/

    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] if not @service

        prefix = @getPrefix(editor, bufferPosition)
        return [] unless prefix != null

        # We only autocomplete after splitters, so there must be at least one word, one splitter, and another word
        # (the latter which could be empty).
        elements = prefix.split(/(->|::)/)
        return [] unless elements.length > 2

        objectBeingCompleted = elements[elements.length - 3].trim()

        failureHandler = () =>
            # Just return no results.
            return []

        successHandler = (values) =>
            currentClassInfo = values[0]
            classInfo = values[1]

            mustBeStatic = false
            hasDoubleDotSeparator = false

            if elements[elements.length - 2] == '::'
                hasDoubleDotSeparator = true

                if objectBeingCompleted != 'parent'
                    mustBeStatic = true

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            currentClassParents = []

            if currentClassInfo?
                currentClassParents = currentClassInfo.parents

            return @addSuggestions(classInfo, elements[elements.length - 1].trim(), hasDoubleDotSeparator, (element) =>
                # Constants are only available when statically accessed (actually not entirely correct, they will
                # work in a non-static context as well, but it's not good practice).
                return false if mustBeStatic and not element.isStatic

                if objectBeingCompleted != '$this'
                    # Explicitly checking for '$this' allows files that are being require-d inside classes to define
                    # a type override annotation for $this and still be able to access private and protected members
                    # there.
                    return false if element.isPrivate and element.declaringClass.name != currentClassInfo?.name
                    return false if element.isProtected and element.declaringClass.name != currentClassInfo?.name and element.declaringClass.name not in currentClassParents

                return true
            , insertParameterList)

        resultingTypeSuccessHandler = (className) =>
            return [] unless className
            return [] if @service.isBasicType(className)

            getRelevantClassInfoHandler = (classInfo) =>
                return classInfo

            return @service.getClassInfo(className, true).then(
                getRelevantClassInfoHandler,
                failureHandler
            )

        resultingTypeAtPromise = @service.getResultingTypeAt(editor, bufferPosition, true, true).then(
            resultingTypeSuccessHandler,
            failureHandler
        )

        if objectBeingCompleted != '$this'
            # We only need this data above under the same condition.
            currentClassNameGetClassInfoHandler = (currentClass) =>
                return null if not currentClass

                getClassInfoHandler = (currentClassInfo) =>
                    return currentClassInfo

                return @service.getClassInfo(currentClass, true).then(getClassInfoHandler, failureHandler)

            determineCurrentClassNamePromise = @service.determineCurrentClassName(editor, bufferPosition, true).then(
                currentClassNameGetClassInfoHandler,
                failureHandler
            )

        else
            determineCurrentClassNamePromise = null

        return Promise.all([determineCurrentClassNamePromise, resultingTypeAtPromise]).then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {Object}   classInfo                     Info about the class to show members of.
     * @param {string}   prefix                        Prefix to match (may be left empty to list all members).
     * @param {boolean}  hasDoubleDotSeparator
     * @param {callback} filterCallback                A callback that should return true if the item should be added
     *                                                 to the suggestions list.
     * @param {bool}     insertParameterList           Whether to insert a list of parameters for methods.
     *
     * @return {array}
    ###
    addSuggestions: (classInfo, prefix, hasDoubleDotSeparator, filterCallback, insertParameterList = true) ->
        suggestions = []

        if hasDoubleDotSeparator
            suggestions.push
                text              : 'class'
                type              : 'keyword'
                replacementPrefix : prefix
                leftLabel         : 'string'
                rightLabelHTML    : @getSuggestionRightLabel('class', {declaringStructure: {name: classInfo.name}})
                description       : 'PHP static class keyword that evaluates to the FCQN.'
                className         : 'php-integrator-autocomplete-plus-suggestion'

        processList = (list, type) =>
            for name, member of list
                if filterCallback and not filterCallback(member)
                    continue

                text = (if type == 'property' and hasDoubleDotSeparator then '$' else '') + member.name

                suggestions.push
                    text              : text
                    type              : type
                    snippet           : if type == 'method' and insertParameterList then @getFunctionSnippet(member.name, member) else null
                    displayText       : text
                    replacementPrefix : prefix
                    leftLabel         : @getClassShortName(member.return?.type)
                    rightLabelHTML    : @getSuggestionRightLabel(name, member)
                    description       : if member.descriptions.short? then member.descriptions.short else ''
                    className         : 'php-integrator-autocomplete-plus-suggestion' + if member.isDeprecated then ' php-integrator-autocomplete-plus-strike' else ''

        processList(classInfo.methods, 'method')
        processList(classInfo.constants, 'constant')
        processList(classInfo.properties, 'property')

        return suggestions
