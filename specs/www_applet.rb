
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

describe "'value ='" do

  it "evaluates value if array" do
    o = WWW_Applet.new [
      "my val", "value =", [1,2,3, "go forth", []]
    ]
    o.write_function "go forth", lambda { |o,n,v|
      o.stack.push 4
    }
    o.run
    o.values["my val"].should == [1,2,3,4]
  end

end # === describe

describe "'computer ='" do

  it "does not evaluate Array" do
    o = WWW_Applet.new [
      "my func", "computer =", [1,2,3, "a", []]
    ]
    o.run
    o.values["my func"].first.tokens.should == [1,2,3,"a",[]]
  end

  it "sets scope to origin scope" do
    o = WWW_Applet.new [
      "my func", "computer =", [1,2,3, "a", []]
    ]
    o.run
    o.values["my func"].first.scope.should == o
  end

end # === describe value as is

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
    a = WWW_Applet.new ["split", ["1 2 3"], "plus_1_and_join", []]
    a.write_function "split", lambda { |obj, name, vals|
      forked = obj.fork_and_run(name, vals)
      forked.stack.last.split
    }

    a.write_function "plus_1_and_join", lambda { |obj, name, vals|
      obj.stack.last.map { |i| Integer(i) + 1 }.join " "
    }

    a.run
    a.stack.last.should == "2 3 4"
  end

  it "stops if the function returns :fin" do
    o = WWW_Applet.new ["a", 1, 2, "yo_yo", [], "no fun", []]
    o.write_function "yo_yo", lambda { |o, n, v| :fin }
    o.run
    o.stack.should == ["a", 1, 2]
  end

  it "continues if the function returns :cont" do
    o = WWW_Applet.new [1, 2, "go_forth", [], 5]
    o.write_function "go_forth", lambda { |o, n, v| o.stack.push(3); :cont }
    o.write_function "go_forth", lambda { |o, n, v| 4 }
    o.run
    o.stack.should == [1,2,3,4,5]
  end

  it "runs function in its own fork" do
    o = WWW_Applet.new [1, 2, "three", ["four", []]]
    o.write_function "three", lambda { |o,n,v|
      o.stack.concat [3,3,3]
      :ignore_return
    }
    o.write_function "four", lambda { |o,n,v|
      o.stack.push 4
      5
    }
    o.run
    o.stack.should == [1,2,3,3,3]
  end

  it "raises Invalid if function returns an unknown Ruby Symbol" do
    o = WWW_Applet.new ["f", []]
    o.write_function "f", lambda { |o,n,v|
      :go_forth
    }
    lambda { o.run }.should.raise(WWW_Applet::Invalid).
      message.should.match /Unknown operation: :go_forth/i
  end

  it "raises Value_Not_Found if the name of the value belongs to an outside scope value" do
    o = WWW_Applet.new [
      "my val", "value =", ["a"],
      "my comp", "computer =", [
        [],[],
        "upcase", ["value", ["my val"]]
      ]
    ]
  end

end # === describe :run


