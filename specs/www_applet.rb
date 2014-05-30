
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
      "my val", "value =", ["go forth", []]
    ]
    o.write_computer "go forth", lambda { |o,n,v| 4 }
    o.run
    o.value("my val").should == 4
  end

  it "saves value with uppercase." do
    o = WWW_Applet.new [
      "my val", "value =", [5]
    ]
    o.run
    o.values("MY VAL").should == 5
  end

  it "raise Too_Many_Values if more than one value is passed." do
    o = WWW_Applet.new [ "my val", "value =", [1,5] ]
    lambda { o.run }.should.raise(WWW_Applet::Too_Many_Values).
      message.should.match /.value =. \[1,\ ?5\]/i
  end

  it "raises Value_Already_Created if value already exists." do
    o = WWW_Applet.new [
      "my val", "value =", [1],
      "mY vAl", "value =", [2]
    ]
    lambda { o.run }.should.raise(WWW_Applet::Value_Already_Created).
      message.should.match /my val/i
  end

end # === describe

describe "'computer ='" do

  it "does not evaluate Array" do
    o = WWW_Applet.new [
      "my func", "computer =", [1,2,3, "a", []]
    ]
    o.run
    o.computers("my func").first.tokens.should == [1,2,3,"a",[]]
  end

  it "sets scope to origin scope" do
    o = WWW_Applet.new [
      "my func", "computer =", [1,2,3, "a", []]
    ]
    o.run
    o.values("my func").first.scope.should == o
  end

end # === describe value as is

describe "Computer run:" do

  it "runs a local function first." do
    o = WWW_Applet.new [
      "yo", "computer =", [ "console print", ["yo yo"] ],
      "my func", "computer =", [
         "yo", "computer =", [ "console print", ["hello"] ],
         "yo", []
      ]
    ]
    o.run
    o.console.should == ["hello"].inspect
  end

  it "runs an a function from parent computer, if not found locally" do
    o = WWW_Applet.new [
      "yo", "computer =", [ "console print", ["yo yo: from top"] ],
      "my func", "computer =", [
         "yo", []
      ]
    ]
    o.run
    o.console.should == ["yo yo: from top"].inspect
  end

end # === describe Computer run:

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


