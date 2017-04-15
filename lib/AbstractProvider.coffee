module.exports =

##*
# Base class for providers.
##
class AbstractProvider
    ###*
     * The regular expression that is used for the prefix.
    ###
    regex: ''

    ###*
     * The class selectors for which autocompletion triggers.
    ###
    scopeSelector: '.source.php'

    ###*
     * The inclusion priority of the provider.
    ###
    inclusionPriority: 1

    ###*
     * Let base autocomplete-plus handle the actual filtering, that way we don't need to manually filter (e.g. using
     * fuzzaldrin) ourselves and the user can configure filtering settings on the base package.
    ###
    filterSuggestions: true

    ###*
     * The class selectors autocompletion is explicitly disabled for (overrules the {@see scopeSelector}).
    ###
    disableForScopeSelector: '.source.php .comment, .source.php .string'

    ###*
     * The service (that can be used to query the source code and contains utility methods).
    ###
    service: null

    ###*
     * Contains global package settings.
    ###
    config: null

    ###*
     * Constructor.
     *
     * @param {Config} config
    ###
    constructor: (@config) ->
        @excludeLowerPriority = @config.get('disableBuiltinAutocompletion')

        @config.onDidChange 'disableBuiltinAutocompletion', (newValue) =>
            @excludeLowerPriority = newValue

    ###*
     * Initializes this provider.
     *
     * @param {mixed} service
    ###
    activate: (@service) ->

    ###*
     * Deactives the provider.
    ###
    deactivate: () ->

    ###*
     * Entry point for all requests from autocomplete-plus.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     * @param {string}     scopeDescriptor
     * @param {string}     prefix
     *
     * @return {Promise|array}
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        throw new Error("This method is abstract and must be implemented!")

    ###*
     * Builds the signature for a PHP function or method.
     *
     * @param {array}  info Information about the function or method.
     *
     * @return {string}
    ###
    getFunctionParameterList: (info) ->
        body = "("

        isInOptionalList = false

        for param, index in info.parameters
            description = ''
            description += '['   if param.isOptional and not isInOptionalList
            description += ', '  if index != 0
            description += '...' if param.isVariadic
            description += '&'   if param.isReference
            description += '$' + param.name
            description += ' = ' + param.defaultValue if param.defaultValue?
            description += ']'   if param.isOptional and index == (info.parameters.length - 1)

            isInOptionalList = param.isOptional

            if not param.isOptional
                body += description

            else
                body += description

        body += ")"

        return body

    ###*
     * Builds the right label for a PHP function or method.
     *
     * @param {array}  info Information about the function or method.
     *
     * @return {string}
    ###
    getSuggestionRightLabel: (info) ->
        # Determine the short name of the location where this item is defined.
        declaringStructureShortName = ''

        if info.declaringStructure and info.declaringStructure.name
            return @getClassShortName(info.declaringStructure.name)

        return declaringStructureShortName

    ###*
     * Builds the snippet for a PHP function or method.
     *
     * @param {string} name The name of the function or method.
     * @param {array}  info Information about the function or method.
     *
     * @return {string}
    ###
    getFunctionSnippet: (name, info) ->
        if info.parameters.length > 0
            return name + '($0)'

        return name + '()$0'

    ###*
     * Retrieves the short name for the specified class name (i.e. the last segment, without the class namespace).
     *
     * @param {string} className
     *
     * @return {string}
    ###
    getClassShortName: (className) ->
        return null if not className

        parts = className.split('\\')
        return parts.pop()

    ###*
     * @param {Array} typeArray
     *
     * @return {String}
    ###
    getTypeSpecificationFromTypeArray: (typeArray) ->
        typeNames = typeArray.map (type) =>
            return @getClassShortName(type.type)

        return typeNames.join('|')

    ###*
     * Retrieves the prefix matches using the specified buffer position and the specified regular expression.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     * @param {String}     regex
     *
     * @return {Array|null}
    ###
    getPrefixMatchesByRegex: (editor, bufferPosition, regex) ->
        # Unfortunately the regex $ doesn't seem to match the end when using backwardsScanInRange, so we match the regex
        # manually.
        line = editor.getBuffer().getTextInRange([[bufferPosition.row, 0], bufferPosition])

        matches = regex.exec(line)

        return matches if matches
        return null

    ###*
     * Retrieves the prefix using the specified buffer position and the current class' configured regular expression.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     *
     * @return {String|null}
    ###
    getPrefix: (editor, bufferPosition) ->
        matches = @getPrefixMatchesByRegex(editor, bufferPosition, @regex)

        if matches
            # We always want the last match, as that's closest to the cursor itself.
            match = matches[matches.length - 1]

            # Turn undefined, which happens if the capture group has nothing to catch, into a valid string.
            return '' if not match?
            return match

        return null
