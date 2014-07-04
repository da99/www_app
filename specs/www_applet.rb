
describe "HTML" do

  it "produces links" do
    target %^<a href="/here">Here</a>^

    actual do
      a(:href=>'/here' ) { "Here" }
    end
  end

  it "escapes :href" do
    target %^<a href="&amp;%20&amp;%20&amp;">Escape</a>^ 

    actual do
      a(:href=>'& & &') { "Escape" }
    end
  end

  it "escapes inner text" do
    target %^<p>&amp; here lies jackie</p>^ 

    actual do
      p { "& here lies jackie" }
    end
  end

end # === describe WWW_Applet.new ===


describe "Style" do

  it "creates a style tag within html>head" do
    target :style, %^
      p {
        background-color : #fff;
      }
    ^

    actual do
      style(:p=>{'background-color'=>'#fff'})
    end
  end

end # === describe Style ===


describe "element styles" do

  it "adds a property to default id" do
    target :style, "
      #p_1 {
        background-color : #000;
        color : #fff;
      }
    "

    actual do
      p {
        style(
          'background-color' => '#000',
          'color' => '#fff'
        )
        "hello"
      }
    end
  end

  it "adds a :class attribute" do
    target :body, '<p id="p_1" class="loud">Loud</p>'

    actual do
      p {
        send :class, "loud"
        "Loud"
      }
    end
  end

end # === describe

describe "element scripts" do

  it "adds a script based on default id" do
    target :script, %^
      WWW_Applet.element("#p_1").on_click("change_style", ["background-color", "#fff"]);
    ^

    actual do
      p {
        on_click :change_style, ['background-color', '#fff']
      }
    end
  end

end # === describe element scripts ===



