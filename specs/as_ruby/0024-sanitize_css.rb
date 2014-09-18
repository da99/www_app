
describe "Sanitize :css" do

  it "does not accept vars for css values" do
    target :style, %^
      div {
        border: something;
      }
    ^
    actual {
      div {
        border :something
      }
    }
  end

  it "does not accept vars for css -image values" do
    target :style, %^
      div {
        background-image: url(something);
      }
    ^
    actual {
      div {
        background_image :something
      }
    }
  end

end # === describe Sanitize :css ===

