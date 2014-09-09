
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

end # === describe :^

describe "HTML attributes" do

  it "merges classes: a.warning(:class=>\"super low\")" do
    target '<a class="warning super low" href="/now">Now</a>'

    actual do
      a.warning(:class => "super low", :href => "/now") { "Now" }
    end
  end

  it "merges multiple missing methods into class: a.warn.low.super() {}" do
    target '<a class="warning super low" href="/today">Today</a>'

    actual do
      a.warning.super.low(:href => "/today") { "Today" }
    end
  end

  it "adds 'id' attribute for unknown bang methods: a.warn!(...) { }" do
    target '<a id="warn" href="/there">There</a>'

    actual do
      a.warn!(:href=>'/there') { "There" }
    end
  end

end # === describe WWW_Applet.new ===




