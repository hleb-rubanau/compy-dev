### REPL

This project is the minimum code for reading text from the user with the built-in input widget. It is very light on functionality, only echoing back the text the user enters.

#### Using user input

Input is callback-driven, not polled. You show the widget once and hand it a function to run each time the user submits a line — there is no handle to create and nothing to check every frame:

```lua
compy.input.show{
  on_text_entered = function(text)
    print(text)
  end,
}
```

`compy.input.show` puts the widget on screen. When the user presses Enter, `on_text_entered` is called with the line they typed. By default the widget stays shown and the field is cleared for the next line, so this single call is a complete read-and-repeat loop — a REPL — with nothing else to write. Escape does nothing unless you ask it to.

That is the *advanced* input surface. For a single question rather than a continuous prompt, the *basic* surface is `compy.ask("Your name?")` with a `compy.on_answer` callback. Validated input — accepting only text that passes checks you supply — is the subject of the neighbouring 'valid' project.
