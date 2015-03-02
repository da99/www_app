

describe "it runs" do

  it "runs" do
    WWW_App.new {
      div {
        "test"
      }
    }.render.should == "<div>test</div>"
  end

end # === describe IS_DEV ===

