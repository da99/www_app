
describe :css do

  it "raises Invalid if class name has invalid chars: class=\"hi;o\"" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual {
        div.^('hi;o') { 
          border '1px solid #fff'
          'hi o'
        }
      }
    }.message.should.match /hi;o/
  end

  it "raises ArgumentError if css value has invalid chars: something *" do
    should.raise(ArgumentError) {
      actual do
        div {
          background 'something *'
        }
      end
    }.message.should.match /something \*/
  end

  it 'raises Invalid if css selector has invalid chars: s*s' do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div.^("s*s") { border '1px'}
      end
    }.message.should.match /s\*s/
  end

  it "raises ArgumentError if contains 'expression:'" do
    should.raise(ArgumentError) {
      actual do
        div {
          background 'solid expression:'
        }
      end
    }.message.should.match /expression:/
  end

  it "raises ArgumentError if contains 'expression&'" do
    should.raise(ArgumentError) {
      actual do
        div {
          background 'solid expression&'
        }
      end
    }.message.should.match /expression&/
  end

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


  # ==========================================================================
  # ===========  end sanitization specs  =====================================
  # ==========================================================================


  it 'allows css selectors with valid chars: #my_box div.box' do
    target :style, <<-EOF
      #my_box div.box {
        border: 1px;
      }
    EOF

    actual {
      div.id(:my_box) {
        div.^(:box) { border '1px' }
      }
    }
  end

  it "adds a 'style' tag to 'head'" do
    target :outer, :style, %^
      <style type="text/css">
        #the_box {
          border-width: 10px;
        }
      </style>
    ^

    actual do
      div.id(:the_box) {
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
      div.id(:my_box) {
        border_width '1px'
      }
    end
  end

  it "uses tag hierarchy if no id found" do
    target :style, %^
      div div span {
        width: 20px;
      }
    ^

    actual do
      div { div { span { width '20px' } } }
    end
  end

  it "does not include parents when element has id" do
    target :style, <<-EOF
      #my_box div.box {
        border: 15px;
      }
    EOF

    actual do
      div.^(:top) {
        div.id(:my_box) {
          div.^(:box) { border '15px' }
        }
      }
    end
  end


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

  it "turns numbers into strings" do
    target :style, %^
      div {
        margin: 0;
      }
    ^
    actual {
      div {
        margin 0
      }
    }
  end # === it turns numbers into strings

end # === sanitize css selectors


