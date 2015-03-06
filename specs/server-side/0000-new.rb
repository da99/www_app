

describe "it runs" do

  it "runs" do
    WWW_App.new {
      div {
        "test"
      }
    }.to_html.should == "<div>test</div>"
  end

end # === describe IS_DEV ===

