

describe "WWW_Applet:" do

  describe ".to_html" do

    it "produces links" do
      actual = to_html {
        a('/here' ) { "Here" }
      }
      should_equal actual, %^<a href="/here">Here</a>^
    end

  end # === describe WWW_Applet.new ===

end # === describe Ruby specific




