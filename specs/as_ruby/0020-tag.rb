
describe :tag do

  it "raises Invalid if tag starts w/ a number" do
    should.raise(Escape_Escape_Escape::Invalid) {
      actual do
        div.*('0a') { 'hello' }
      end
    }.message.should.match /0a/
  end

  it "raises Invalid if tag is unknown: e.g. :footers" do
    should.raise(StandardError) {
      actual do
        tag(:footers) { 'bye' }
      end
    }.message.should.match /footers/
  end

end # === describe :tag ===

