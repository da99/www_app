
describe "HTML" do

  it "produces 'a' elements with 'href'" do
    target %^<a href="/here">Here</a>^

    actual do
      a(:href=>'/here' ) { "Here" }
    end
  end

  it "produces elements with class: a.warning => <a class=\"warning\" ..." do
    target %^<a class="warning" href="/here">Here</a>^

    actual do
      a.warning(:href=>'/here' ) { "Here" }
    end
  end

end # === describe WWW_Applet.new ===




