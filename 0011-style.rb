

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
