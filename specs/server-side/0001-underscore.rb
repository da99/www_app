
describe :_ do

  it "let's you add :id to the body" do
    actual = WWW_App.new {
      _.id(:the_body)
    }.to_html

    actual[/<body[^\<]+/].should == %!<body id="the_body">!
  end # === it lets you add :id to the body

  it "let's you add a :class to body" do
    actual = WWW_App.new {
      _.^(:sad)
    }.to_html

    actual[/<body[^\<]+/].should == %!<body class="sad">!
  end # === it lets you add a :class to body

  it "let's you create a style inside a tag, outside of :style" do
    target :style, <<-EOF
      #main.happy:link {
        color: #happy;
      }

      #main.sad {
        border: 1px dashed red;
      }
    EOF

    actual do
      div.id(:main) {
        _.^(:happy)._link { color '#happy' }
        _.^(:sad)   { border '1px dashed red' }
      }
    end
  end # === it let's you create a style inside a tag, outside of :style

  it "refers to the :body when used inside a parent-less :style" do
    target :style, %!
      body {
        color: #abc;
      }
    !

    actual do
      style {
        _ {
          color '#abc'
        }
      }
    end
  end # === it refers to the :body when used inside a parent-less :style

  it "can be used with double-underscore: _.__div" do
    target :style, %^
      #main.sad div.happy {
        color: #confused;
      }
    ^

    actual do
      div.id(:main).^(:sad) {
        style {
          _.__.div.^(:happy) {
            color '#confused'
          }
        }
      }
    end
  end # === it can be used with double-underscore: _.__div

end # === describe :_
