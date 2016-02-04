## 0.5.1 (base 0.5.0)
### Bugs fixed
* Fixed the `yield` keyword not being suggested.
* Fixed the `class` keyword introduced in PHP 5.5 not being completed after two dots.

## 0.5.0 (base 0.5.0)
### Features and enhancements
* Only (non-abstract) classes will be suggested after the new keyword.
* A new keyword provider will also show autocompletion for PHP keywords.
* The parameter list for methods will now be displayed in a different style for better visual recognition.
* A new snippet provider will now suggest a few useful snippets such as for `isset`, `unset`, `catch`, and more.
* When autocompleting use statements, the suggestions will now have a different icon to indicate that it is an import.
* Traits will now receive the 'mixin' type (which by default has the same icon as a 'class') to allow for separate styling.
* Parameters for functions and methods will still be shown during completion, but will no longer actually be completed anymore. Instead, your cursor will be put between the parentheses. As a replacement, please consider using the [php-integrator-call-tips](https://github.com/Gert-dev/php-integrator-call-tips) package (if you're not already), which can now provide call tips instead. Call tips are an improvement as there is no longer a need to remove parameters you don't want and jump around using tab.

### Bugs fixed
* Fixed autocompletion not properly completing and working with static class property access, such as `static::$foo->bar()`.
* Autocompletion will now also trigger on a backslash for class names (i.e. `My\Namespace\` didn't trigger any autocompletion before, whilst `My\Namespace\A` did).

## 0.4.0 (base 0.4.0)
### Features and enhancements
* The placement of use statements has been improved.
* Added a new autocompletion provider that will provide snippets for tags in docblocks.
* The class provider will now show a documentation URL for built-in classes, interfaces and traits.
* Added a new command that sorts use statements according to the same algorithm that manages adding them.
* The class provider will now show the type of the structural element (trait, interface or class) in the left label.
* We no longer depend on fuzzaldrin directly. Filtering suggestions is now handled by the base autocomplete-plus package, allowing your configurations there to also take effect in this package.
* $this will now always list private and protected members, which allows files that are being require-d inside classes to define a type override annotation for $this and still be able to access private and protected members there.
* The order in which providers are registered has slightly changed; this results in things that are more interesting being shown first, such as members, class names and variable names. Global constants and functions are 'less important' and are shown further down the list. Note that this only applies if, after filtering (fuzzy matching), there are suggestions present from multiple providers.

### Bugs fixed
* Fixed use statements ending up at an incorrect location in some situations.
* Fixed a use statement still being added when starting a class name with a leading slash.
* Fixed duplicate use statements being added in some cases with certain (unformatted) sorting combinations.
* Fixed an unnecessary use statement being added when selecting the current class name during autocompletion.
* When the base package service is not available, autocompletion will silently fail instead of spawning errors.

## 0.3.0
### Features and enhancements
* Documentation for classes will now be shown during autocompletion.

### Bugs fixed
* Fixed variables containing numbers not being suggested.
* Use statements were still added if one was already present with a leading slash.
* An error would sometimes be shown when trying to autocomplete a class that did not exist.
* The partial name of the variable being autocompleted is now no longer included in the suggestions.

## 0.2.1
### Bugs fixed
* Global functions inside namespaces were not being autocompleted properly.
* Class names that start with a lower case letter will now also be autocompleted.
* Class names were not being completed in some locations such as inside if statements.
* Added a new configuration option that disables the built-in PHP autocompletion provider (enabled by default). `[1]`

`[1]` This will solve the problem where built-in functions such as `array_walk` were showing up twice, once from this package and once from Atom's PHP support itself.

## 0.2.0
### Features and enhancements
* Autocompletion now works inside double quoted strings `[1]`.
* When autocompleting variable names, their type is now displayed, if possible.
* Where possible, autocompletion is now asynchronous (using promises), improving performance.
* The right label of class members in the autocompletion window will now display the originating structure (i.e. class, interface or trait).
* The way use statements are added and class names are completed was drastically improved.
  * Multiple cursors are now properly supported.
  * The appropriate namespace will now be added if you are trying to do a relative import:

```php
<?php

// Select My\Foo\FooClass as suggestion.
Foo\FooClass

// The result (before):
use My\Foo\FooClass;

FooClass

// The result (after):
use My\Foo;

Foo\FooClass
```

`[1]` This might also complete in a few rare erroneous cases as well (e.g. `{SomeClass::test}` instead of `{${SomeClass::test}}`), but it's better to have autocompletion for common used cases and in a few rare erroneous cases than no autocompletion at all.

### Bugs fixed
* Autocompletion of class names inside comments will now no longer work.
* Class autocompletion will now work when the cursor is at the start of a line.
* Restrictions for function and constant autocompletion is now more relaxed. You will now receive autocompletion after `if (!` for built-in PHP functions and constants.

## 0.1.0
* Initial release.
