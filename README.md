# Sublime Zsh Integration

This is a small utility to help you integrate your shell more with Sublime Text.

To call this python code from your shell, you should source the
SublimeZshIntegration.zsh in your `.zshrc`.

If you use my plugin manager, you can manage both the sublime and zsh plugin by initializing the plugin like this:
```zsh
zpm trobjo/SublimeZshIntegration,\
           where:'$XDG_CONFIG_HOME/sublime-text/Packages/SublimeZshIntegration',\
           if:'command -v subl'
```

Restart your shell, and now the enter key key, if pressed when the buffer is empty will take you to the directory of the currently edited file in Sublime Text.
