
NAME:             user

/define
  name:           username
  is:             one_line_text
  length between: 3, 10
  only chars:     a-z A-Z 0-9 _ - *
  unique:         enforce

/after_create



