module.exports =
    ###*
     * Configuration settings.
    ###
    config:
        disableBuiltinAutocompletion:
            title       : 'Disable built-in PHP autocompletion from Atom'
            description : 'Atom also provides some default autocompletion for PHP, which includes function names for
                           some common PHP functions, but without their parameters (just their names). If this is
                           checked, these will be surpressed and not show up in autocompletion. If you uncheck this,
                           function names may show up twice: once from this package and once from Atom itself.'
            type        : 'boolean'
            default     : true
            order       : 1

        insertNewlinesForUseStatements:
            title       : 'Insert newlines for use statements'
            description : 'When enabled, additional newlines are inserted before or after an automatically added
                           use statement when they can\'t be nicely added to an existing \'group\'. This results in
                           more cleanly separated use statements but will create additional vertical whitespace.'
            type        : 'boolean'
            default     : false
            order       : 2

        automaticallyAddUseStatements:
            title       : 'Automatically add use statements when necessary'
            description : 'When enabled, a use statement will be added when autocompleting a class name (if it isn\'t
                           already present).'
            type        : 'boolean'
            default     : true
            order       : 3

        largeListRefreshTimeout:
            title       : 'Timeout before refreshing large data (global functions, global constants, class list, ...)'
            description : 'Because the contents of these large lists changes rarely in most code bases, they are
                           refreshed less often than other items. The amount of time (in milliseconds) specified here
                           will need to pass after the last reindexing occurs (in any editor).'
            type        : 'string'
            default     : '5000'
            order       : 4

    ###*
     * The name of the package.
    ###
    packageName: 'php-integrator-autocomplete-plus'

    ###*
     * The configuration object.
    ###
    configuration: null

    ###*
     * List of tooltip providers.
    ###
    providers: []

    ###*
     * Registers any commands that are available to the user.
    ###
    registerCommands: () ->
        Utility = require './Utility'

        atom.commands.add 'atom-workspace', "php-integrator-autocomplete-plus:sort-use-statements": =>
            activeTextEditor = atom.workspace.getActiveTextEditor()

            return if not activeTextEditor

            Utility.sortUseStatements(activeTextEditor, @configuration.get('insertNewlinesForUseStatements'))

    ###*
     * Activates the package.
    ###
    activate: ->
        AtomConfig                      = require './AtomConfig'
        MemberProvider                  = require './MemberProvider'
        SnippetProvider                 = require './SnippetProvider'
        ClassProvider                   = require './ClassProvider'
        GlobalConstantProvider          = require './GlobalConstantProvider'
        VariableProvider                = require './VariableProvider'
        GlobalVariableProvider          = require './GlobalVariableProvider'
        TypeHintNewVariableNameProvider = require './TypeHintNewVariableNameProvider'
        MagicConstantProvider           = require './MagicConstantProvider'
        GlobalFunctionProvider          = require './GlobalFunctionProvider'
        KeywordProvider                 = require './KeywordProvider'
        DocblockAnnotationProvider      = require './DocblockAnnotationProvider'
        DocblockTagProvider             = require './DocblockTagProvider'

        @configuration = new AtomConfig(@packageName)

        @registerCommands()

        @providers.push(new SnippetProvider(@configuration))
        @providers.push(new MemberProvider(@configuration))
        @providers.push(new TypeHintNewVariableNameProvider(@configuration))
        @providers.push(new VariableProvider(@configuration))
        @providers.push(new GlobalFunctionProvider(@configuration))
        @providers.push(new GlobalConstantProvider(@configuration))
        @providers.push(new ClassProvider(@configuration))
        @providers.push(new GlobalVariableProvider(@configuration))
        @providers.push(new MagicConstantProvider(@configuration))
        @providers.push(new KeywordProvider(@configuration))
        @providers.push(new DocblockAnnotationProvider(@configuration))
        @providers.push(new DocblockTagProvider(@configuration))

    ###*
     * Deactivates the package.
    ###
    deactivate: ->
        @deactivateProviders()

    ###*
     * Activates the providers using the specified service.
    ###
    activateProviders: (service) ->
        for provider in @providers
            provider.activate(service)

    ###*
     * Deactivates any active providers.
    ###
    deactivateProviders: () ->
        for provider in @providers
            provider.deactivate()

        @providers = []

    ###*
     * Sets the php-integrator service.
     *
     * @param {mixed} service
     *
     * @return {Disposable}
    ###
    setService: (service) ->
        @activateProviders(service)

        {Disposable} = require 'atom'

        return new Disposable => @deactivateProviders()

    ###*
     * Retrieves a list of supported autocompletion providers.
     *
     * @return {array}
    ###
    getProviders: ->
        return @providers
