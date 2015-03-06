
describe "page_title" do

  it "creates only one :title tag" do
    WWW_App.new {
      page_title { 'yo' }
    }.to_html.scan(/<title>[^>]+<\/title>/).
    should == ['<title>yo</title>']
  end # === it creates on :title tag

end # === describe "page_title"
