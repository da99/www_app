
describe "Sanitize :css" do

  it "does not accept vars for css values" do
    target :style, %^
      div {
        border: something;
      }
    ^
    actual {
      div {
        border :something
      }
    }
  end

  it "does not accept vars for css -image values" do
    target :style, %^
      div {
        background-image: url(something);
      }
    ^
    actual {
      div {
        background_image :something
      }
    }
  end

end # === describe Sanitize :css ===


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


