
describe ":style block" do

  it "does not render empty style classes: div {  }" do
      target :style, <<-EOF
        div a {
          color: #fff;
        }
      EOF

      actual do
        style {
          div { a { color '#fff' } }
        }
      end
  end

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
      p { 'empty' }
    end
  end # === it does not add anything 

  it "allows multiple use of the same :id" do
    target :style, %^
      #main {
        color: #fff;
      }

      #main {
        background: #fff;
      }
    ^
    actual do
      style {
        div.id(:main) { color '#fff' }
        div.id(:main) { background '#fff' }
      }
      div.id(:main) { 'main' }
    end
  end

  it "renders nested styles" do
    target :style, %^
      #main {
        border: 1px solid grey;
      }

      #main a.high {
         border: 2px solid blue;
      }
    ^

    actual do
      style {
        div.id(:main) {
          border '1px solid grey'
          a.^(:high) {
            border '2px solid blue'
          }
        }
      } # === style
    end
  end # === it renders nested styles

  it "includes parent when rendering" do
    target :style, %^
      div.main #ham {
        color: #cheese;
      }
    ^
    actual do
      div.^(:main) do
        style {
          p.id(:ham) { color '#cheese' }
        }
      end
    end
  end # === it includes parent when rendering

end # === describe "css pseudo"
