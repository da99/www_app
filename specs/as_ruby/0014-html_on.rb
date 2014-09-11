
describe "HTML :on" do

  it "adds class to id of element: #id.class" do
    target :style, %^
      #me.highlight {
        border-color: #fff;
      }
    ^

    actual do
      div.*(:me) {
        on(:highlight) { border_color '#fff' }
      }
    end
  end

  it "adds a psuedo class if passed a String" do
    target :style, <<-EOF
      a:hover {
        border: 12px;
      }
    EOF

    actual {
      a.href('/home') {
        on(':hover') { border '12px' }
      }
    }
  end

end # === describe


