
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
    update :top
    every 5
    with '/success/#stuff'

    template(:stuff, data[:stuff]) {
      div.^(:stuff) {
        var(:content)
      }
    } # template :stuff

  }

} # div.creations


