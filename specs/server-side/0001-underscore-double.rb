
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

  it "can be used with :_ in :style: div.__._ { ... }" do
    target :style, %^
      div.outside #main.inner {
        color: #deep;
      }
    ^

    actual do
      div.id(:main) {
        style {
          div.^(:outside).__._.^(:inner) {
            color '#deep'
          }
        }
      }
    end
  end # === it can be used with :_ in :style: div.__._ { ... }

end # === describe :underscore__double
