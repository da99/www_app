
Buttons
=========================

```
   button.^(:submit) { 'Save" }
   button.^(:cancel, :red) { 'Cancel" }
   button.^(:blue, :yell) { 'Save" }
```

This behavior is special to buttons:
  All buttons
    when clicked
    run each event from class names
    ignore if event does not exist.

Input
=========================

```
  input(:text, :my_name, 'Robert')
  input(:text, 'Robert')
  input(:pass_phrase)
```

This behaviour is special to inputs:
  when :input is in 
    fieldset with one or more class names:
      the first class name is the default name.
      if class name is :password,
        type is set to :password
        if first arg is Symbol,
          name is set to first arg.
      else
        type is set to :text
      if last arg is String,
        value is set to last arg.
  else
    return super
