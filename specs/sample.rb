
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

      #
      # 1) due date/time
      # 2) Limit/# of respones
      # 3) mark as done
      # 4) Collect info.
      # 5) No limit of response
      # 6) Text/story.
      # 7) Match response
      #
      div.^(:activity).data(:sort, r.created_at.to_i) {
        if r.timer?
        end
      }

    } # template :stuff

  }

} # div.creations


