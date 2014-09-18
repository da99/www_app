
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

end # === describe HTML contents

