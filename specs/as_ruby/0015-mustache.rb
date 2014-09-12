
describe :mustache do

  it "replaces values with hash" do
    target <<-EOF
      <div>hello</div>
    EOF

    actual greeting: 'hello' do
      div { :greeting }
    end
  end

  it "raises ContextMiss for unauthorized methods" do
    should.raise(Mustache::ContextMiss) {
      target "nothing"
      actual name: 'Bob' do
        div { :object_id }
      end
    }.message.should.match /Can't find :object_id/i
  end

  it "raises ContextMiss when an unknown value is requested" do
    should.raise(Mustache::ContextMiss) {
      actual name: 'Bob' do
        div { :object_ids }
      end
    }.message.should.match /object_ids/
  end

end # === describe :mustache
