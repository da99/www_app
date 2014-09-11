
describe "Sanitize: html" do

  it "escapes attributes" do
    target %^<a rel="&lt;hello">hello</a>^
    actual {
      a.rel('<hello') { 'hello' }
    }
  end

  it "escapes chars in 'href' attributes as a url" do
    target %^<a href="&#47;home&#47;?a&amp;b">home</a>^

    actual do
      a.href('/home/?a&b') { "home" }
    end
  end

  it "escapes inner text" do
    target %^<p>&amp; here lies jack</p>^

    actual do
      p { "& here lies jack" }
    end
  end

  it "strips out W3C unallowed Unicode chars" do
    target %^<div>hello      hello</div>^
    actual do
      div { "hello \u0340\u0341\u17a3\u17d3\u2028\u2029 hello" }
    end
  end

  it "raises Invalid_HREF for :href: javacript:" do
    should.raise(Escape_Escape_Escape::Invalid_HREF) {
      actual do
        a.href('javascript://alert()') { 'hello' }
      end
    }.message.should.match /javascript/
  end

end # === describe HTML ===


describe "Sanitize: css values" do

  it "sanitizes urls" do
    target :style, <<-EOF
      div.box {
        background-image: url(http:&#47;&#47;www.example.com&#47;back.png);
      }
    EOF

    actual do
      div.^(:box) {
        background_image 'http://www.example.com/back.png'
      }
    end
  end

  it "raises Invalid if contains 'expression:'" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div {
          background 'solid expression:'
        }
      end
    }.message.should.match /expression:/
  end

  it "raises Invalid if contains 'expression&'" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div {
          background 'solid expression&'
        }
      end
    }.message.should.match /expression&/
  end

  it "raises Invalid non-css allowed chars: * ( + ) etc." do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div {
          background 'something *'
        }
      end
    }.message.should.match /something \*/
  end

end # === Sanitize css values


describe "Sanitize: css selectors" do

  it 'raises Invalid if css selector has invalid chars: *' do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div.^(:"s*s") { border '1px'}
      end
    }.message.should.match /invalid chars/
  end

  it 'allows css selectors with valid chars: #my_box div.box' do
    target :style, <<-EOF
      #my_box div.box {
        border: 1px;
      }
    EOF

    actual {
      div.*(:my_box) {
        div.^(:box) { border '1px' }
      }
    }
  end

end # === sanitize css selectors






