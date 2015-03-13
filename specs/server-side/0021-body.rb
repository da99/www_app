
describe "body with inner style" do

  it "adds styles to page as: body { ... }" do
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
