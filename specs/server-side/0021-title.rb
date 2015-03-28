
describe "page_title" do

  it "creates only one :title tag" do
    html = WWW_App.new {
      title { 'yo' }
    }.to_html

    html.scan(/<title>[^>]+<\/title>/).
    should == ['<title>yo</title>']
  end # === it creates on :title tag

  it "accepts a String argument" do
    html = WWW_App.new {
      title 'yo yo string'
    }.to_html

    html.scan(/<title>[^>]+<\/title>/).
    should == ['<title>yo yo string</title>']
  end # === it accepts a String argument

end # === describe "page_title"
