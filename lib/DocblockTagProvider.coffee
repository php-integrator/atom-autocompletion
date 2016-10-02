AbstractProvider = require "./AbstractProvider"

module.exports =

##*
# Provides autocompletion for docblock tags.
##
class DocblockTagProvider extends AbstractProvider
    ###*
     * @inheritdoc
     *
     * These can only appear in docblocks. Including the space in the capturing group ensures that autocompletion will
     * start right after putting down an asterisk instead of when the tag symbol '@' is entered.
    ###
    regex: /^\s*(?:\/\*)?\*(\s@\S*)$/

    ###*
     * @inheritdoc
    ###
    scopeSelector: '.comment.block.documentation.phpdoc.php'

    ###*
     * @inheritdoc
    ###
    disableForScopeSelector: ''

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
            documentationUrl = null

            if tag.documentationName
                documentationUrl =
                    @config.get('phpdoc_base_url').prefix +
                    tag.documentationName +
                    @config.get('phpdoc_base_url').suffix

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                type                : 'tag',
                description         : 'PHP docblock tag.'
                descriptionMoreURL  : documentationUrl
                snippet             : tag.snippet
                displayText         : tag.name
                replacementPrefix   : prefix

        return suggestions

    ###*
     * Retrieves a list of known docblock tags.
     *
     * @return {array}
    ###
    fetchTagList: () ->
        return [
            {name: '@api',            documentationName : 'api',            snippet : '@api$0'}
            {name: '@author',         documentationName : 'author',         snippet : '@author ${1:name} ${2:[email]}$0'}
            {name: '@copyright',      documentationName : 'copyright',      snippet : '@copyright ${1:description}$0'}
            {name: '@deprecated',     documentationName : 'deprecated',     snippet : '@deprecated ${1:[vector]} ${2:[description]}$0'}
            {name: '@example',        documentationName : 'example',        snippet : '@example ${1:example}$0'}
            {name: '@filesource',     documentationName : 'filesource',     snippet : '@filesource$0'}
            {name: '@ignore',         documentationName : 'ignore',         snippet : '@ignore ${1:[description]}$0'}
            {name: '@inheritDoc',     documentationName : 'inheritDoc',     snippet : '@inheritDoc$0'}
            {name: '@internal',       documentationName : 'internal',       snippet : '@internal ${1:description}$0'}
            {name: '@license',        documentationName : 'license',        snippet : '@license ${1:[url]} ${2:name}$0'}
            {name: '@link',           documentationName : 'link',           snippet : '@link ${1:uri} ${2:[description]}$0'}
            {name: '@method',         documentationName : 'method',         snippet : '@method ${1:type} ${2:name}(${3:[parameter list]})$0'}
            {name: '@package',        documentationName : 'package',        snippet : '@package ${1:package name}$0'}
            {name: '@param',          documentationName : 'param',          snippet : '@param ${1:mixed} \$${2:parameter} ${3:[description]}$0'}
            {name: '@property',       documentationName : 'property',       snippet : '@property ${1:type} ${2:name} ${3:[description]}$0'}
            {name: '@property-read',  documentationName : 'property-read',  snippet : '@property-read ${1:type} ${2:name} ${3:[description]}$0'}
            {name: '@property-write', documentationName : 'property-write', snippet : '@property-write ${1:type} ${2:name} ${3:[description]}$0'}
            {name: '@return',         documentationName : 'return',         snippet : '@return ${1:type} ${2:[description]}$0'}
            {name: '@see',            documentationName : 'see',            snippet : '@see ${1:URI or FQSEN} ${2:description}$0'}
            {name: '@since',          documentationName : 'since',          snippet : '@since ${1:version} ${2:[description]}$0'}
            {name: '@source',         documentationName : 'source',         snippet : '@source ${1:start line} ${2:number of lines} ${3:[description]}$0'}
            {name: '@throws',         documentationName : 'throws',         snippet : '@throws ${1:exception type} ${2:[description]}$0'}
            {name: '@todo',           documentationName : 'todo',           snippet : '@todo ${1:description}$0'}
            {name: '@uses',           documentationName : 'uses',           snippet : '@uses ${1:FQSEN} ${2:[description]}$0'}
            {name: '@var',            documentationName : 'var',            snippet : '@var ${1:type} ${2:\$${3:[property]} ${4:[description]}}$0'}
            {name: '@version',        documentationName : 'version',        snippet : '@version ${1:vector} ${2:[description]}$0'}
        ]
