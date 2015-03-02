
describe :_link do

  it "adds :link pseudo-class" do
    target :style, <<-EOF
      a:link {
        color: #fff;
      }
    EOF

    actual do
      a {
        _link { color '#fff' }
      }
    end
  end # === it

end # === describe :style
