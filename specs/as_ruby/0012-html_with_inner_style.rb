
describe "HTML with inner style" do

  it "uses id of element to add style" do
    target :style, %^
      #my_box {
        border-width: 1px;
      }
    ^

    actual do
      div.my_box! {
        border_width '1px'
      }
    end
  end

  it "uses a default id when id is not specified" do
    target :style, %^
      #div_1 {
        width: 20px;
      }
    ^

    actual do
      div {
        width '20px'
      }
    end
  end

end # === describe
