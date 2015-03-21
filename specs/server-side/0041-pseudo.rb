
describe "pseudo classes" do

  it "adds tag to :body when used outside of :style" do
    target :body, <<-EOF
      <a id="main" href="&#47;test">test</a>
    EOF
    actual do
      a.id(:main).href("/test") { 
        _link { color '#fff' }
        "test"
      }
    end
  end # === it adds tag to :body when used outside of :style

  it "uses :id in :style tag if specified" do
    target :style, <<-EOF
      #main:link {
        color: #ffc;
      }
    EOF
    actual do
      a.id(:main).href("/test") { 
        _link { color '#ffc' }
        "test"
      }
    end
  end # === it uses :id in :style tag if specified

  it "allows multiple pseudos" do
    target :style, <<-EOF
      a:link, a:visited {
        color: #fff;
      }
      a:hover {
        color: #ccc;
      }
    EOF
    actual do
      a {
        _link / _visited   { color '#fff' }
        _hover { color '#ccc' }
      }
    end
  end # === it allows multiple pseudos when used inside a style tag

end # === describe :pseudo_classes

