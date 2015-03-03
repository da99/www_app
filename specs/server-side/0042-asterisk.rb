
describe :asterisk do

  it "defines multiple css classes" do
    target :style, %^
      a:link, a:visited, a:hover {
        color: #fff;
      }
    ^

    actual do
      a._link * a._visited * a._hover {
        color '#fff'
      }
    end
  end # === it defines multiple css classes

end # === describe :asterisk
