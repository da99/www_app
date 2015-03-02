
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

  it "adds tag to :body when used outside of :style" do
    target :body, <<-EOF
      <a id="main" href="&#47;test">test</a>
    EOF
    actual do
      a.*(:main).href("/test") { 
        _link { color '#fff' }
        "test"
      }
    end
  end # === it adds tag to :body when used outside of :style

  it "uses :id in :style tag if specified" do
    target :style, <<-EOF
      #main:link {
        color: #ffc;
      }
    EOF
    actual do
      a.*(:main).href("/test") { 
        _link { color '#ffc' }
        "test"
      }
    end
  end # === it uses :id in :style tag if specified

end # === describe "css pseudo"
