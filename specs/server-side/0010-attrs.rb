
describe "all attrs" do

  it "raises a RuntimeError if tag has an invalid attribute" do
    should.raise(RuntimeError) {
      actual {
        a.href('/href').src('file') {
          "here"
        }
      }
    }.message.should.match /:src not allowed to be set here/
  end

  it "escapes attributes" do
    target %^<a rel="&lt;hello">hello</a>^
    actual {
      a.rel('<hello') { 'hello' }
    }
  end

end # === describe all attrs







