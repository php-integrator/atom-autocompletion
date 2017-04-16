DocblockTagProvider = require "./DocblockTagProvider"

module.exports =

##*
# Provides autocompletion for PHP-unit annotation tags.
##
class PHPUnitTagProvider extends DocblockTagProvider
    ###*
     * @inheritdoc
    ###
    getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
        return [] unless @config.get('enablePhpunitAnnotationTags')
        super

    ###*
     * @inheritdoc
    ###
    addSuggestions: (tagList, prefix) ->
        suggestions = []

        for tag in tagList
            documentationUrl = @config.get('phpunit_annotations_base_url').prefix

            if tag.documentationName
                documentationUrl += @config.get('phpunit_annotations_base_url').id_prefix + tag.documentationName

            # NOTE: The description must not be empty for the 'More' button to show up.
            suggestions.push
                type                : 'tag',
                description         : tag.description
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
            {name: '@after',                          documentationName: 'after',                          snippet: '@after',                                       description: 'The method should be called after each test method in a test case class'}
            {name: '@afterClass',                     documentationName: 'afterClass',                     snippet: '@afterClass',                                  description: 'The static method should be called after all test methods in a test class have been run to clean up shared fixtures'}
            {name: '@backupGlobals',                  documentationName: 'backupGlobals',                  snippet: '@backupGlobals ${1:disabled}',                 description: 'Completely enable or disable the backup and restore operations for global variables'}
            {name: '@backupStaticAttributes',         documentationName: 'backupStaticAttributes',         snippet: '@backupStaticAttributes ${1:disabled}',        description: 'Back up all static property values in all declared classes before each test and restore them afterwards'}
            {name: '@before',                         documentationName: 'before',                         snippet: '@before',                                      description: 'The method should be called before each test method in a test case class'}
            {name: '@beforeClass',                    documentationName: 'beforeClass',                    snippet: '@beforeClass',                                 description: 'The static method should be called before any test methods in a test class are run to set up shared fixtures'}
            {name: '@codeCoverageIgnore',             documentationName: 'codeCoverageIgnore',             snippet: '@codeCoverageIgnore',                          description: 'Exclude lines of code from the coverage analysis'}
            {name: '@codeCoverageIgnoreEnd',          documentationName: 'codeCoverageIgnoreEnd',          snippet: '@codeCoverageIgnoreEnd',                       description: 'Exclude lines of code from the coverage analysis'}
            {name: '@codeCoverageIgnoreStart',        documentationName: 'codeCoverageIgnoreStart',        snippet: '@codeCoverageIgnoreStart',                     description: 'Exclude lines of code from the coverage analysis'}
            {name: '@covers',                         documentationName: 'covers',                         snippet: '@covers ${1:method}',                          description: 'Specify which method(s) the test method wants to test'}
            {name: '@coversDefaultClass',             documentationName: 'coversDefaultClass',             snippet: '@coversDefaultClass ${1:class}',               description: 'Specify a default namespace or class name for @covers annotation'}
            {name: '@coversNothing',                  documentationName: 'coversNothing',                  snippet: '@coversNothing',                               description: 'Specify no code coverage information will be recorded for the annotated test case'}
            {name: '@dataProvider',                   documentationName: 'dataProvider',                   snippet: '@dataProvider ${1:provider}',                  description: 'Specify the data provider method'}
            {name: '@depends',                        documentationName: 'depends',                        snippet: '@depends ${1:test}',                           description: 'Specify the test method this test depends'}
            {name: '@expectedException',              documentationName: 'expectedException',              snippet: '@expectedException ${1:exception}',            description: 'Specify the exception that must be thrown inside the test method'}
            {name: '@expectedExceptionCode',          documentationName: 'expectedExceptionCode',          snippet: '@expectedExceptionCode ${1:code}',             description: 'Specify the code for exception set by @expectedException'}
            {name: '@expectedExceptionMessage',       documentationName: 'expectedExceptionMessage',       snippet: '@expectedExceptionMessage ${1:message}',       description: 'Specify the messege for exception set by @expectedException'}
            {name: '@expectedExceptionMessageRegExp', documentationName: 'expectedExceptionMessageRegExp', snippet: '@expectedExceptionMessageRegExp ${1:message}', description: 'Specify the messege as a regular expression for exception set by @expectedException'}
            {name: '@group',                          documentationName: 'group',                          snippet: '@group ${1:group}',                            description: 'Tag a test as belonging to one or more groups'}
            {name: '@large',                          documentationName: 'large',                          snippet: '@large',                                       description: 'An alias for @group large'}
            {name: '@medium',                         documentationName: 'medium',                         snippet: '@medium',                                      description: 'An alias for @group medium'}
            {name: '@preserveGlobalState',            documentationName: 'preserveGlobalState',            snippet: '@preserveGlobalState ${1:disabled}',           description: 'Prevent PHPUnit from preserving global state'}
            {name: '@requires',                       documentationName: 'requires',                       snippet: '@requires ${1:preconditions}',                 description: 'Skip tests when common preconditions are not met'}
            {name: '@runInSeparateProcess',           documentationName: 'runInSeparateProcess',           snippet: '@runInSeparateProcess',                        description: 'Indicates that a test should be run in a separate PHP process'}
            {name: '@runTestsInSeparateProcesses',    documentationName: 'runTestsInSeparateProcesses',    snippet: '@runTestsInSeparateProcesses',                 description: 'Indicates that all tests in a test class should be run in a separate PHP process'}
            {name: '@small',                          documentationName: 'small',                          snippet: '@small',                                       description: 'An alias for @group small'}
            {name: '@testdox',                        documentationName: 'testdox',                        snippet: '@testdox',                                     description: ''}
            {name: '@ticket',                         documentationName: 'ticket',                         snippet: '@ticket',                                      description: ''}
            {name: '@uses',                           documentationName: 'uses',                           snippet: '@uses',                                        description: 'Specify the code which will be executed by a test, but is not intended to be covered by the test'}
        ]
