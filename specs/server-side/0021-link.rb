
describe :link do

  it "raises Invalid_Relative_HREF" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual do
        link.href('http://www.google.com/')./
      end
    }.message.should.match /google/
  end

  it "escapes slashes in :href" do
    target = %^<link type="text/css" rel="stylesheet" href="&#47;css&#47;css&#47;styles.css" />^
    WWW_App.new {
      link.href('/css/css/styles.css')./
    }.to_html.scan(target).should == [target]
  end

  it "gets rendered in :head" do
    html = get_content(:head, WWW_App.new {
      link.type('text/css').rel('stylesheet').href("/file.css")./
    }.to_html)

    html.
    scan(%r!<link [^>]+>!).
    should == [<<-EOF.strip]
      <link type="text/css" rel="stylesheet" href="&#47;file.css" />
    EOF
  end # === it gets rendered in :head

  it "allows a relative :href" do
    target = %^<link type="text/css" rel="stylesheet" href="&#47;css.css" />^
    WWW_App.new {
      link.href('/css.css')./
    }.to_html.scan(target).should == [target]
  end

end # === describe :link
