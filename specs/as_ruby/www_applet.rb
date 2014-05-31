
describe "Ruby specific functionality:" do

  describe ".new" do

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

  describe "#run" do

    it "puts non-function calls on the stack" do
      a = WWW_Applet.new ["a", "b", "c"]
      a.run
      a.stack.should == "a b c".split
    end

    it "calls the proper function" do
      a = WWW_Applet.new ["1 2 3", "split", [], "plus_1_and_join", []]
      a.write_computer "split", lambda { |obj, name, vals|
        forked = obj.fork_and_run(name, vals)
        forked.stack.push obj.stack.last
        forked.stack.last.split
      }

      a.write_computer "plus_1_and_join", lambda { |obj, name, vals|
        obj.stack.last.map { |i| Integer(i) + 1 }.join " "
      }

      a.run
      a.stack.last.should == "2 3 4"
    end

    it "stops if the function returns :fin" do
      o = WWW_Applet.new ["a", 1, 2, "yo_yo", [], "no fun", []]
      o.write_computer "yo_yo", lambda { |o, n, v| :fin }
      o.run
      o.stack.should == ["a", 1, 2]
    end

    it "continues if the function returns :cont" do
      o = WWW_Applet.new [1, 2, "go_forth", [], 5]
      o.write_computer "go_forth", lambda { |o, n, v| o.stack.push(3); :cont }
      o.write_computer "go_forth", lambda { |o, n, v| 4 }
      o.run
      o.stack.should == [1,2,3,4,5]
    end

    it "runs function in its own fork" do
      o = WWW_Applet.new [1, 2, "three", ["four", []]]
      o.write_computer "three", lambda { |o,n,v|
        o.stack.concat [3,3,3]
        :ignore_return
      }
      o.write_computer "four", lambda { |o,n,v|
        o.stack.push 4
        5
      }
      o.run
      o.stack.should == [1,2,3,3,3]
    end

    it "raises Invalid if function returns an unknown Ruby Symbol" do
      o = WWW_Applet.new ["f", []]
      o.write_computer "f", lambda { |o,n,v|
        :go_forth
      }
      lambda { o.run }.should.raise(WWW_Applet::Invalid).
        message.should.match /Unknown operation: :go_forth/i
    end

  end # === describe :run

end # === describe Ruby specific


Dir.glob("specs/as_json/*.json").each { |f|
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



