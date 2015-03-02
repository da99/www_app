
describe "css pseudo" do

  %w[link visited hover].each { |name|
    it "adds :#{name} pseudo-class" do
      target :style, <<-EOF
        a:#{name} {
          color: #fff;
        }
      EOF

      actual do
        style {
          a {
            send("_#{name}".to_sym) { color '#fff' }
          }
        }
      end
    end # === it
  }

  it "does not add anything to :body" do
    target :body, <<-EOF
      <p>empty</p>
    EOF

    actual do
      style {
        a { _link { color '#fff' } }
      }
      p {
        'empty'
      }
    end
  end # === it does not add anything 
end # === describe "css pseudo"
