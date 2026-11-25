#!/bin/sh
# Le numéro (pour `--screen`) de l'écran intégré du MacBook : les fenêtres d'essai s'ouvrent là, jamais sur un moniteur
# externe. Godot numérote les écrans dans le même ordre que macOS.
osascript -l JavaScript -e 'ObjC.import("AppKit"); var s = $.NSScreen.screens, found = 0;
for (var i = 0; i < s.count; i++) { if (/built-in|color lcd|intégré/i.test(s.objectAtIndex(i).localizedName.js)) found = i }
found'
