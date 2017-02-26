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
    disableForScopeSelector: '.source.php .comment, .source.php .string.quoted.single'

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
            getClassInfoResults = values[1]

            getClassInfoResults = getClassInfoResults.filter (item) ->
                return item?

            return [] if getClassInfoResults.length == 0

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

            if not currentClassParents?
                currentClassParents = []

            return @addSuggestions(getClassInfoResults, elements[elements.length - 1].trim(), hasDoubleDotSeparator, (element) =>
                # Constants are only available when statically accessed (actually not entirely correct, they will
                # work in a non-static context as well, but it's not good practice).
                return false if mustBeStatic and not element.isStatic
                return true
            , insertParameterList)

        resultingTypesSuccessHandler = (types) =>
            classTypePromises = []

            getRelevantClassInfoDataHandler = (classInfo) =>
                return classInfo

            getRelevantClassInfoDataFailureHandler = (classInfo) =>
                return null

            for type in types
                continue if @service.isBasicType(type)

                classTypePromises.push @service.getClassInfo(type).then(
                    getRelevantClassInfoDataHandler,
                    getRelevantClassInfoDataFailureHandler
                )

            return Promise.all(classTypePromises)

        resultingTypesAtPromise = @service.getResultingTypesAt(editor, bufferPosition, true).then(
            resultingTypesSuccessHandler,
            failureHandler
        )

        if objectBeingCompleted != '$this'
            # We only need this data above under the same condition.
            currentClassNameGetClassInfoHandler = (currentClass) =>
                return null if not currentClass

                getClassInfoHandler = (currentClassInfo) =>
                    return currentClassInfo

                return @service.getClassInfo(currentClass).then(getClassInfoHandler, failureHandler)

            determineCurrentClassNamePromise = @service.determineCurrentClassName(editor, bufferPosition).then(
                currentClassNameGetClassInfoHandler,
                failureHandler
            )

        else
            determineCurrentClassNamePromise = null

        return Promise.all([determineCurrentClassNamePromise, resultingTypesAtPromise]).then(successHandler, failureHandler)

    ###*
     * Returns available suggestions.
     *
     * @param {Array}    classInfoObjects
     * @param {string}   prefix                        Prefix to match (may be left empty to list all members).
     * @param {boolean}  hasDoubleDotSeparator
     * @param {callback} filterCallback                A callback that should return true if the item should be added
     *                                                 to the suggestions list.
     * @param {bool}     insertParameterList           Whether to insert a list of parameters for methods.
     *
     * @return {array}
    ###
    addSuggestions: (classInfoObjects, prefix, hasDoubleDotSeparator, filterCallback, insertParameterList = true) ->
        suggestions = []

        for classInfo in classInfoObjects
            processList = (list, type) =>
                for name, member of list
                    if filterCallback and not filterCallback(member)
                        continue

                    if type == 'constant' and not hasDoubleDotSeparator
                        # Constants can only be accessed statically. Also, it would cause the built-in PHP 5.5 'class'
                        # keyword to be listed as member after ->, overriding any property with the name 'class'.
                        continue

                    text = (if type == 'property' and hasDoubleDotSeparator then '$' else '') + member.name
                    typesToDisplay = if type == 'method' then member.returnTypes else member.types

                    displayText = text

                    if 'parameters' of member
                        displayText += @getFunctionParameterList(member)

                    leftLabel = ''

                    if member.isPublic
                        leftLabel += '<span class="icon icon-globe import">&nbsp;</span>'

                    else if member.isProtected
                        leftLabel += '<span class="icon icon-shield">&nbsp;</span>'

                    else if member.isPrivate
                        leftLabel += '<span class="icon icon-lock selector">&nbsp;</span>'

                    leftLabel += @getTypeSpecificationFromTypeArray(typesToDisplay)

                    suggestions.push
                        text              : text
                        type              : type
                        snippet           : if type == 'method' and insertParameterList then @getFunctionSnippet(member.name, member) else null
                        displayText       : displayText
                        replacementPrefix : prefix
                        leftLabelHTML     : leftLabel
                        rightLabelHTML    : @getSuggestionRightLabel(member)
                        description       : if member.shortDescription then member.shortDescription else ''
                        className         : 'php-integrator-autocomplete-plus-suggestion php-integrator-autocomplete-plus-has-additional-icons' + if member.isDeprecated then ' php-integrator-autocomplete-plus-strike' else ''

            processList(classInfo.methods, 'method')
            processList(classInfo.constants, 'constant')
            processList(classInfo.properties, 'property')

        return suggestions
