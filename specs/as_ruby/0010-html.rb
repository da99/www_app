
describe "HTML" do

  it "produces links" do
    target %^<a href="/here">Here</a>^

    actual do
      a(:href=>'/here' ) { "Here" }
    end
  end

end # === describe WWW_Applet.new ===




