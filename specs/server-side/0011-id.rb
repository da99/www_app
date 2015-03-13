


describe :id do

  it "raises Invalid if id has invalid chars" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div.id('a<&a') { 'hello' }
      end
    }.message.should.match /a<&a/
  end

  it "raises HTML_ID_Duplicate if id is used more than once" do
    should.raise(WWW_App::HTML_ID_Duplicate) {
      actual do
        div.id(:my_id) { '1' }
        div.id(:my_id) { '2' }
      end
    }.message.should.match /my_id/
  end

  # ==========================================================================
  # ===========  end sanitization specs  =====================================
  # ==========================================================================


  it "adds 'id' attribute: a.*(:warning)(...) { }" do
    target '<a id="warning" href="&#47;there">There</a>'

    actual do
      a.id(:warning).href('/there') { "There" }
    end
  end

end # === describe WWW_App.new ===



