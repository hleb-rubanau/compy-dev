### Input validation

As an extension to the user input functionality, the input widget accepts arbitrary user-specified filters through a validator.
A "filter" is a function, which takes a string as input and returns a boolean value of whether it is valid and an optional `Error`.
The `Error` is structure which contains the error message (`msg`), and the location the error comes from, with line and character fields (`l` and `c`).

Example:
```lua
function non_empty(s)
  if string.ulen(s) == 0 then
     return false, Error('Input is empty!')
  end
  return true
end
```
This is not a particularly useful validator, as the input will not be accepted and ran through the validations if it doesn't contain anything, but it demonstrates the idea quite well.

Filters will be run line-by-line, if the input has multiple lines, the line number is also indicated when it's invalid.
For increased visual usefulness, your validations can report on the first character which does not satisfy the criteria required:
```lua
function min_length(n)
  return function(s)
    local l = string.ulen(s)
    if n < l then
      return true
    end
    return false, Error("too short!", l)
  end
end
```
This will result the entered text being red starting from the problem location.

Of course, this means in some cases that the line has to be validated char-by-char. To facilitate this, we provide the `string.forall()` helper, and a `Char` table containing some classifier functions.
`string.forall()` takes a validation function and runs it on each character, returning `true` if the string is valid, or `false` and the index of the offending character:
```lua
function is_lower(s)
  local ok, err_c = string.forall(s, Char.is_lower)
  if ok then
    return true
  end
  return false, Error("should be lowercase", err_c)
end
```

If you're curious about the details, check out `is_upper()`, which provides a manual implementation.

#### Invoking

Pass your filters to `compy.input.show` under the `validator` key, wrapped in `LineValidators`:

```lua
compy.input.show{
  validator = LineValidators({ non_empty }),
  on_text_entered = function(text) print(text) end,
}
```

Validations are applied by passing an array of functions to `LineValidators`. Note the lack of parentheses after the function name, we don't want to call it yet, just refer to it by name. Each filter runs on every submitted line, and the line is accepted only if all of them pass.

#### Helper functions

* `string.ulen(s)` - as opposed to the builtin `len()`, this works for unicode strings
* `string.usub(s, from, to)` - unicode substrings
* `Char.is_alpha(c)` - is `c` a letter
* `Char.is_alnum(c)` - is `c` a letter or a number (alphanumeric)
* `Char.is_lower(c)` - is `c` lowercase
* `Char.is_upper(c)` - is `c` uppercase
* `Char.is_digit(c)` - is `c` a number
* `Char.is_space(c)` - is `c` whitespace
* `Char.is_punct(c)` - is `c` punctuation (!, ?, &, ;, parentheses, ...)

Note that determining if something is a letter, or what case it is only reliable for the english alphabet.

* `Error(msg, c, l)` - for creating errors, `l` and `c` are optional
