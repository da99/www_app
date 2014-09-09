
describe "HTML contents" do

  it "uses last String value as content" do
    target %^<p>Hello</p>^

    actual do
      p { "Hello" }
    end
  end

end # === describe HTML contents

