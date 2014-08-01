
describe "HTML with inner style" do

  it "adds a 'style' tag to 'head'" do
    target :outer, :style, %^
      <style type="text/css">
        #the_box {
          border-width: 10px;
        }
      </style>
    ^

    actual do
      div.the_box! {
        border_width '10px'
      }
    end
  end

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
        #div_0 {
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
