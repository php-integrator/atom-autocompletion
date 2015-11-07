{TextEditor} = require 'atom'

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
    selector: '.source.php'

    ###*
     * The inclusion priority of the provider.
    ###
    inclusionPriority: 1

    ###*
     * The class selectors autocompletion is explicitly disabled for (overrules the {@see selector}).
    ###
    disableForSelector: '.source.php .comment, .source.php .string'

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
     * Builds the snippet for a PHP function or method.
     *
     * @param {string} name     The name of the function or method.
     * @param {array}  elements The (optional and required) parameters.
     *
     * @return {string}
    ###
    getFunctionSnippet: (name, elements) ->
        body = name + "("
        lastIndex = 0

        # Non optional elements
        for arg, index in elements.parameters
            body += ", " if index != 0
            body += "${" + (index+1) + ":" + arg + "}"
            lastIndex = index+1

        # Optional elements. One big same snippet
        if elements.optionals.length > 0
            body += "${" + (lastIndex + 1) + ":["

            body += ", " if lastIndex != 0

            lastIndex += 1

            for arg, index in elements.optionals
                body += ", " if index != 0
                body += arg
            body += "]}"

        body += ")"

        # Ensure the user ends up after the inserted text when he's done cycling through the parameters with tab.
        body += "$0"

        return body

    ###*
     * Builds the signature for a PHP function or method.
     *
     * @param {string} word     The name of the function or method.
     * @param {array}  elements The (optional and required) parameters.
     *
     * @return {string}
    ###
    getFunctionSignature: (word, element) ->
        snippet = @getFunctionSnippet(word, element)

        # Just strip out the placeholders.
        signature = snippet.replace(/\$\{\d+:([^\}]+)\}/g, '$1')

        return signature[0 .. -3]

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
     * Retrieves the prefix using the specified buffer position and the current class' configured regular expression.
     *
     * @param {TextEditor} editor
     * @param {Point}      bufferPosition
     *
     * @return {string}
    ###
    getPrefix: (editor, bufferPosition) ->
        # Get the text for the line up to the triggered buffer position
        line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])

        # Match the regex to the line, and return the match
        matches = line.match(@regex)

        # Looking for the correct match
        if matches?
            for match in matches
                start = bufferPosition.column - match.length
                if start >= 0
                    word = editor.getTextInBufferRange([[bufferPosition.row, bufferPosition.column - match.length], bufferPosition])
                    if word == match
                        # Not really nice hack.. But non matching groups take the first word before. So I remove it.
                        # Necessary to have completion juste next to a ( or [ or {
                        if match[0] == '{' or match[0] == '(' or match[0] == '['
                            match = match.substring(1)

                        return match

        return ''
