
describe :link do

  it "raises Invalid_Relative_HREF" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual do
        link.href('http://www.google.com/')./
      end
    }.message.should.match /google/
  end

  it "escapes slashes in :href" do
    target %^<link href="&#47;css&#47;css&#47;styles.css" />^
    actual {
      link.href('/css/css/styles.css')./
    }
  end

  it "allows a relative :href" do
    target %^<link href="&#47;css.css" />^
    actual {
      link.href('/css.css')./
    }
  end

end # === describe :link
