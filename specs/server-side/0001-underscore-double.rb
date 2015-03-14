
describe :underscore__double do

  it "lets you combine different elements in a css selector" do
    target :style, %^
      div.bad div {
        color: #mebad;
      }
    ^

    actual {
      style {
        div.^(:bad).__.div {
          color '#mebad'
        }
      }
    }
  end # === it lets you combine different elements in a css selector

end # === describe :underscore__double
