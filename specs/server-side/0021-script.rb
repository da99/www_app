
describe :script do

  it "raises Invalid_Relative_HREF if :src is not relative" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual do
        script('http://www.example.org/file.js')
      end
    }.message.should.match /example\.org/
  end

  it "allows a relative :src" do
    target %^<script src="&#47;file.js"></script>^
    actual {
      script('/file.js')
    }
  end

  it "escapes slashes in attr :src" do
    target %^<script src="&#47;dir&#47;file.js"></script>^
    actual {
      script('/dir/file.js')
    }
  end

  it "fails w/ ArgumentError if passed a symbol" do
    should.raise(ArgumentError) {
      actual do
        script(:help)
      end
    }.message.should.match /\:help/
  end

  it "renders :type when given a block" do
    target %^<script type="text/text">hello</script>^
    actual {
      script('text/text') { 'hello' }
    }
  end

  it "includes client-side script files" do
    actual = WWW_App.new {
      div {
        on :click do
          add_class :happy
        end
      }
    }.to_html
    actual.scan(%r@<script src="([^"]+)"></script>@).flatten.
    should == Dir.glob('lib/public/*.js').sort.map { |f|
      Escape_Escape_Escape.relative_href "/www_app-#{File.read('VERSION').strip}/#{File.basename f}"
    }
  end # === it includes client-side script files

  it "is rendered inside a full document" do
    actual = WWW_App.new {
      div {
        on(:click) {
          add_class :happy
        }
      }
    }.to_html

    actual['<body>'].should == '<body>'
  end

end # === describe :JS ===
