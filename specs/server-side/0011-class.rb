


describe :^ do

  it "raises Invalid if class has invalid chars" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual {
        div.^('hi)o') { 'hello' }
      }
    }.message.should.match /hi\)o/
  end


  # ==========================================================================
  # ===========  end sanitization specs  =====================================
  # ==========================================================================


  it "adds 'class' attribute: a.^(:warning, :red) { }" do
    target '<a class="warning red" href="&#47;here">Here</a>'

    actual do
      a.^(:warning, :red).href('/here') { "Here" }
    end
  end

  it "merges classes: a.^(:super).^(:low)" do
    target '<a class="super low" href="&#47;now">Now</a>'

    actual do
      a.^(:super).^(:low).href("/now") { "Now" }
    end
  end

end # === describe :^



