
describe :all do

  it "raises a RuntimeError if tag has an unknown attribute" do
    should.raise(RuntimeError) {
      actual {
        a.href('/href') {
          tag![:attrs][:hi] = 'hiya'
          "here"
        }
      }
    }.message.should.match /Unknown attr: :hi/
  end

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

end # === describe :all







