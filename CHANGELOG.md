## 0.4.0
### Features and enhancements
* The placement of use statements has been improved.
* Added a new autocompletion provider that will provide snippets for tags in docblocks.
* Added a new command that sorts use statements according to the same algorithm that manages adding them.

### Bugs fixed
* Fixed a use statement still being added when starting a class name with a leading slash.
* Fixed an unnecessary use statement being added when selecting the current class name during autocompletion.

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
