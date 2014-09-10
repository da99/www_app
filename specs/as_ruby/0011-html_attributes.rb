
describe :href do

  it "produces 'a' elements with 'href'" do
    target '<a href="/here">Here</a>'

    actual do
      a.href('/here') { "Here" }
    end
  end

end # === describe :href

describe :^ do

  it "adds 'class' attribute: a.^(:warning, :red) { }" do
    target '<a class="warning red" href="/here">Here</a>'

    actual do
      a.^(:warning, :red).href('/here') { "Here" }
    end
  end

  it "merges classes: a.^(:super).^(:low)" do
    target '<a class="super low" href="/now">Now</a>'

    actual do
      a.^(:super).^(:low).href("/now") { "Now" }
    end
  end

end # === describe :^

describe :* do

  it "adds 'id' attribute: a.*(:warning)(...) { }" do
    target '<a id="warning" href="/there">There</a>'

    actual do
      a.*(:warning).href('/there') { "There" }
    end
  end

end # === describe WWW_Applet.new ===




