

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

end # === describe :href
