
describe "WWW_Applet.new" do

  it "accepts a string" do
    o = WWW_Applet.new "[]"
    o.code.should == "[]"
  end

  it "accepts an array" do
    code = ["a", []]
    o = WWW_Applet.new code
    o.code.should == MultiJson.dump(code)
  end

  it "raises WWW_Applet::Invalid if object is not an Array" do
    lambda {
      WWW_Applet.new({a:"a"})
    }.should.raise(WWW_Applet::Invalid).
    message.should.match /JS object must be an array/i
  end

end # === describe WWW_Applet.new ===
