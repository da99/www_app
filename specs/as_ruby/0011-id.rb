


describe :* do

  it "raises Invalid if id has invalid chars" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div.*('a<&a') { 'hello' }
      end
    }.message.should.match /a<&a/
  end

  it "raises HTML_ID_Duplicate if id is used more than once" do
    should.raise(WWW_Applet::HTML_ID_Duplicate) {
      actual do
        div.*(:my_id) { '1' }
        div.*(:my_id) { '2' }
      end
    }.message.should.match /my_id/
  end

  # ==========================================================================
  # ===========  end sanitization specs  =====================================
  # ==========================================================================


  it "adds 'id' attribute: a.*(:warning)(...) { }" do
    target '<a id="warning" href="&#47;there">There</a>'

    actual do
      a.*(:warning).href('/there') { "There" }
    end
  end

end # === describe WWW_Applet.new ===



