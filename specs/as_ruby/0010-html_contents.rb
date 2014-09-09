
describe "HTML contents" do

  it "uses last String value as content" do
    target %^<p>Hello</p>^

    actual do
      p { "Hello" }
    end
  end

  it "creates an :a tag w/ :href:" do
    target %^<a href="/hello">hello</a>^

    actual { a.href('/hello') { 'hello' } }
  end

end # === describe
