
describe :script do

  it "raises Invalid_Relative_HREF if :src is not relative" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual do
        script('http://www.example.org/file.js')
      end
    }.message.should.match /example\.org/
  end

  it "puts custom script files w/ :src at the after vendor files and www_app.js" do
    actual = WWW_App.new {
      p { 'paragraph' }
      script 'my_script.js'
    }.to_html

    script_srcs(actual).last.should == 'my_script.js'
  end # === it puts custom script files w/ :src at the after vendor files and www_app.js

  it "allows a relative :src" do
    actual = WWW_App.new {
      script('/file.js')
    }.to_html

    script_srcs(actual).last.should == %^&#47;file.js^
  end

  it "escapes slashes in attr :src" do
    actual = WWW_App.new {
      script('/dir/file.js')
    }.to_html

    script_srcs(actual).last.should == %^&#47;dir&#47;file.js^
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
      div { }
      script 'my.js'
    }.to_html

    targets = (
      Dir.glob('lib/public/**/*.js').map { |f|
        href = "/www_app-#{File.read('VERSION').strip}/#{f}".sub('/lib/public', '')
        Escape_Escape_Escape.relative_href href
      } + ['my.js']
    )

    script_srcs(actual).sort.should == targets.sort
  end # === it includes client-side script files

  it "is rendered inside a full document" do
    actual = WWW_App.new {
      div { }
      script 'my.js'
    }.to_html

    actual['<body>'].should == '<body>'
  end

  it "allows rendering of child elements" do
    target :body, <<-EOF
      <script type="text/mustache">
        <div>!{ html.hello }!</div>
      </script>
    EOF
    actual do
      script 'text/mustache' do
        div { :hello }
      end
    end
  end # === it allows rendering of child elements

end # === describe :JS ===
