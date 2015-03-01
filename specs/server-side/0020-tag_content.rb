
describe "HTML contents" do

  it "uses last String value as content" do
    target %^<p>Hello</p>^

    actual do
      p { "Hello" }
    end
  end

  it "closes tag with :/" do
    target %^<p></p>^
    actual {
      p./
    }
  end

  it "does not give end-tags to void tags (self-closing tags)" do
    target %^<br />\n<img />^
    actual {
      br./
      img./
    }
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

end # === describe HTML contents

