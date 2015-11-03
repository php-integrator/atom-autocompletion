## 0.2.0
* Autocompletion of class names inside comments will now no longer work.
* Class autocompletion will now work when the cursor is at the start of a line.
* Where possible, autocompletion is now performed asynchronously using promises instead of blocking for a process,
  improving performance.
* Restrictions for function and constant autocompletion is now more relaxed, i.e. after "if (!" you will now receive
  autocompletion for built-in PHP functions and constants.

## 0.1.0
* Initial release.
