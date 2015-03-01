
describe "body with inner style" do

  it "uses 'body' instead of id" do
    target :style, %^
      body {
        border-width: 3px;
      }
    ^

    actual {
      border_width '3px'
    }
  end

end # === describe
