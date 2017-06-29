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

        automaticallyAddUseStatements:
            title       : 'Automatically add use statements when necessary'
            description : 'When enabled, a use statement will be added when autocompleting a class name (if it isn\'t
                           already present).'
            type        : 'boolean'
            default     : true
            order       : 2

        enablePhpunitAnnotationTags:
            title       : 'Autocomplete PHPUnit annotation tags'
            description : 'When enabled, PHPUnit annotation tags will be autocompleted.'
            type        : 'boolean'
            default     : true
            order       : 3

        largeListRefreshTimeout:
            title       : 'Timeout before refreshing large data (global functions, global constants, class list, ...)'
            description : 'Fetching these large lists from the core is almost costless since core 3.0, but due to the
                           sheer amount of data being sent over the socket, there may still be noticeable delays if this
                           setting is set too low. Also, the contents of these lists change relatively rarely during
                           editing. This amount of time (in milliseconds) will pass after successful reindexing before
                           the lists are refetched.'
            type        : 'integer'
            default     : 5000
            order       : 4

        largeListRefreshTimeoutJitter:
            title       : 'Jitter for timeout for refreshing large data'
            description : 'Adds a random amount of jitter (between 0 and this number) to the large list refresh timeout
                           above to ensure the large lists don\'t all get fetched at once. As sockets naturally queue,
                           this adds a more even distribution of load on the socket and ensures other requests don\'t
                           hang up too long.'
            type        : 'integer'
            default     : 3000
            order       : 5

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
     * Activates the package.
    ###
    activate: ->
        AtomConfig                      = require './AtomConfig'
        MemberProvider                  = require './MemberProvider'
        SnippetProvider                 = require './SnippetProvider'
        KeywordProvider                 = require './KeywordProvider'
        NamespaceProvider               = require './NamespaceProvider'
        ClassProvider                   = require './ClassProvider'
        GlobalConstantProvider          = require './GlobalConstantProvider'
        VariableProvider                = require './VariableProvider'
        GlobalVariableProvider          = require './GlobalVariableProvider'
        TypeHintNewVariableNameProvider = require './TypeHintNewVariableNameProvider'
        MagicConstantProvider           = require './MagicConstantProvider'
        GlobalFunctionProvider          = require './GlobalFunctionProvider'
        DocblockAnnotationProvider      = require './DocblockAnnotationProvider'
        DocblockTagProvider             = require './DocblockTagProvider'
        PHPUnitTagProvider              = require './PHPUnitTagProvider'

        @configuration = new AtomConfig(@packageName)

        @providers.push(new SnippetProvider(@configuration))
        @providers.push(new KeywordProvider(@configuration))
        @providers.push(new MemberProvider(@configuration))
        @providers.push(new TypeHintNewVariableNameProvider(@configuration))
        @providers.push(new VariableProvider(@configuration))
        @providers.push(new GlobalFunctionProvider(@configuration))
        @providers.push(new GlobalConstantProvider(@configuration))
        @providers.push(new NamespaceProvider(@configuration))
        @providers.push(new ClassProvider(@configuration))
        @providers.push(new GlobalVariableProvider(@configuration))
        @providers.push(new MagicConstantProvider(@configuration))
        @providers.push(new DocblockAnnotationProvider(@configuration))
        @providers.push(new DocblockTagProvider(@configuration))
        @providers.push(new PHPUnitTagProvider(@configuration))

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
