
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

end # === describe Sanitize js ===
