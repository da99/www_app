
describe "HTML :on" do

  it "adds class to id of element: #id.class" do
    target :style, %^
      #me.highlight {
        border-color: #fff;
      }
    ^

    actual do
      div.me! {
        on.highlight {
          border_color '#fff'
        }
      }
    end
  end

end # === describe



