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
            propertyAccessNeedsDollarSign = false

            objectBeingCompleted = elements[elements.length - 3].trim();

            if elements[elements.length - 2] == '::'
                propertyAccessNeedsDollarSign = true

                if objectBeingCompleted != 'parent'
                    mustBeStatic = true

            characterAfterPrefix = editor.getTextInRange([bufferPosition, [bufferPosition.row, bufferPosition.column + 1]])
            insertParameterList = if characterAfterPrefix == '(' then false else true

            nestedSuccessHandler = (classInfo) =>
                return @addSuggestions(classInfo, elements[elements.length - 1].trim(), propertyAccessNeedsDollarSign, (element) =>
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
     * Returns available suggestions.
     *
     * @param {Object}   classInfo                     Info about the class to show members of.
     * @param {string}   prefix                        Prefix to match (may be left empty to list all members).
     * @param {boolean}  propertyAccessNeedsDollarSign
     * @param {callback} filterCallback                A callback that should return true if the item should be added
     *                                                 to the suggestions list.
     * @param {bool}     insertParameterList           Whether to insert a list of parameters for methods.
     *
     * @return {array}
    ###
    addSuggestions: (classInfo, prefix, propertyAccessNeedsDollarSign, filterCallback, insertParameterList = true) ->
        suggestions = []

        processList = (list, type) =>
            for name, member of list
                if filterCallback and not filterCallback(member)
                    continue

                text = (if type == 'property' and propertyAccessNeedsDollarSign then '$' else '') + member.name

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
