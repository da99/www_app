
describe "Ruby specific functionality:" do

  describe ".new" do

    it "accepts a String" do
      o = WWW_Applet.new "[]"
      o.tokens.should == MultiJson.load("[]")
    end

    it "accepts an Array" do
      code = ["a", []]
      o = WWW_Applet.new code
      o.tokens.should == code
    end

    it "raises \"Invalid\" if object is not an Array" do
      lambda {
        WWW_Applet.new({a:"a"})
      }.should.raise(RuntimeError).
      message.should.match /Invalid: JS object must be an array/i
    end

  end # === describe WWW_Applet.new ===

end # === describe Ruby specific


Dir.glob("specs/as_json/*.json").sort.each { |f|
  contents = MultiJson.load(File.read(f))
  describe "'#{File.basename(f).gsub(/\A\d+-|\.json\Z/, '').gsub('_', ' ')}'" do
    contents.each { |t|
      it t["it"] do
        i = WWW_Applet.new(t["input"])
        o = WWW_Applet_Test.new(i, t["output"])
        o.run
      end
    }
  end
}



