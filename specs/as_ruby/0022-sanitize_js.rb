
describe "Sanitize js" do

  it "escapes text as :html" do
    target :script, <<-EOF
      WWW_Applet.compile(
        ["create_event",["div","click","add_class",["red&lt;red"]]]
      );
    EOF

    actual do
      div {
        on(:click) { add_class "red<red" }
      }
    end
  end

  it "does not allow vars in :script :src attribute" do
    target :body, <<-EOF
      <script src="help"></script>
    EOF

    actual do
      script.src(:help)
    end
  end

  it "does not allow blocks in :script" do
    should.raise(RuntimeError) {
      actual {
        script.src('/hello.js') {}
      }
    }.message.should.match /Block not allowed in :script/
  end

end # === describe Sanitize js ===
