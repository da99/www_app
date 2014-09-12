
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
    }.message.should.match /Can't find \.html\(:object_id\)/i
  end

  it "raises ContextMiss when an unknown value is requested" do
    should.raise(Mustache::ContextMiss) {
      actual name: 'Bob' do
        div { :object_ids }
      end
    }.message.should.match /object_ids/
  end

  it "escapes html" do
    target <<-EOF
      <div>&amp; &#47; hello</div>
    EOF

    actual :hello=>'& / hello' do
      div { :hello }
    end
  end

end # === describe :mustache



