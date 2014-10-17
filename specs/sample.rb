
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

div.^(:col, :creations) {

  div.^(:list) {
    update  :top
    every   5
    from    '/success/#stuff'

    template(:activity, records) { |r|
      div.^(:activity) {
        if r.timer?
        end
      }
    } # template :stuff

  }

} # div.creations


