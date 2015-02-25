
NAME:             user

/define
  name:           username
  is:             one_line_text
  length between: 3, 10
  only chars:     a-z A-Z 0-9 _ - *
  unique:         enforce

/after_create

-----------------------------

background {
  url "/imgs/squares.png"
}

div.^(:col, :create) {

  form.*('#stuff') {
    post '/create'

    textarea {
    }

    div.^(:buttons) {
      button.^(:submit) { 'Create' }
    }

  }

} # div.create

div.^(:col).^(:creations) {

  div.^(:list) {

    update  :top
    every   5
    from    '/success/#stuff'

    #
    # 1) due date/time
    # 2) Limit/# of respones
    # 3) mark as done
    # 4) Collect info.
    # 5) No limit of response
    # 6) Text/story.
    # 7) Match response
    #

  } # div.list

} # div.col.creations

----------------------------


title "Hello, World!"

form {
  button "send"
}


col.c_1! {
  box {
    p.first!.hello { "Hiya" }
  }
}

col.c_2! {
  box {
    p.second!.hello.again { 
      border "1px solid #fff"
      "Hiya, again."
    }
  }
}




