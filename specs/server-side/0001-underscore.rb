
describe :_ do

  it "lets you add :id to the body" do
    actual = WWW_App.new {
      _.id(:the_body)
    }.to_html

    actual[/<body[^\<]+/].should == %!<body id="the_body">!
  end # === it lets you add :id to the body

  it "lets you add a :class to body" do
    actual = WWW_App.new {
      _.^(:sad)
    }.to_html

    actual[/<body[^\<]+/].should == %!<body class="sad">!
  end # === it lets you add a :class to body

end # === describe :_
