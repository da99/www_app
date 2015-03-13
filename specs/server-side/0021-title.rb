
describe "page_title" do

  it "creates only one :title tag" do
    html = WWW_App.new {
      title { 'yo' }
    }.to_html

    html.scan(/<title>[^>]+<\/title>/).
    should == ['<title>yo</title>']
  end # === it creates on :title tag

end # === describe "page_title"
