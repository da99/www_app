
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


describe "#extract_first" do

  it "removes first occurance of value" do
    a = WWW_Applet.new ["a", "b", "a"]
    a.extract_first "a"
    a.object.should == ["b", "a"]
  end

  it "removes first occurance if value is a function call" do
    a = WWW_Applet.new ["a", [], "b", [], "a", []]
    a.extract_first "a"
    a.object.should == ["b", [], "a", []]
  end

end # === describe #extract_first

