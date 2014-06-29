

describe "HTML" do

  it "produces links" do
    should_equal %^<a href="/here">Here</a>^ do
      a('/here' ) { "Here" }
    end
  end

  it "escapes :href" do
    should_equal %^<a href="&amp;%20&amp;%20&amp;">Escape</a>^ do
      a('& & &') { "Escape" }
    end
  end

  it "escapes inner text" do
    should_equal %^<p>&amp; here lies jackie</p>^ do
      p('/here/lies') { "& here lies jackie" }
    end
  end

end # === describe WWW_Applet.new ===


describe "Style" do

  it "creates an style tag within html>head" do
    target = to_html(:style=> %^
      p {
        background-color: #fff;
      }
    ^)

    should_equal target do
      style(:p=>{'background-color'=>'#fff'})
    end
  end

end # === describe Style ===



