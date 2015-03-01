
describe "all attrs" do

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

end # === describe all attrs







