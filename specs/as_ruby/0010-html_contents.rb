
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

end # === describe HTML contents

