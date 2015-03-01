

describe :href do

  it "produces 'a' elements with 'href'" do
    target '<a href="&#47;here">Here</a>'

    actual do
      a.href('/here') { "Here" }
    end
  end

  it "escapes chars in 'href' attributes as a url" do
    target %^<a href="&#47;home&#47;?a&amp;b">home</a>^

    actual do
      a.href('/home/?a&b') { "home" }
    end
  end

  it "raises Invalid_HREF for :href: javacript:" do
    should.raise(Escape_Escape_Escape::Invalid_HREF) {
      actual do
        a.href('javascript://alert()') { 'hello' }
      end
    }.message.should.match /javascript/
  end

  it "raises Escape_Escape_Escape::Invalid_Relative_HREF if not relative using :link" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual {
        link.href('http://www.google.com/s.css')./
      }
    }.message.should.match /google/
  end

end # === describe :href
