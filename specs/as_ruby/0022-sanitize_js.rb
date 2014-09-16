
describe "Sanitize js" do

  it "raises Unescaped if :js contains an unidentified string" do
    should.raise(WWW_Applet::Unescaped) {
      WWW_Applet.new {
        div {
          on(:click) { add_class :red }
          js << [:add_class, 'blue']
        }
      }
    }.message.should.match /blue/
  end

end # === describe Sanitize js ===
