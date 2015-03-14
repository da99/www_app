
describe :mustache do

  it "replaces values with hash" do
    target <<-EOF
      <div>hello</div>
    EOF

    actual greeting: 'hello' do
      div { :greeting }
    end
  end

  it "raises ContextMiss for unauthorized methods" do
    should.raise(Mustache::ContextMiss) {
      target "nothing"
      actual name: 'Bob' do
        div { :object_id }
      end
    }.message.should.match /Can't find \.html\(:object_id\)/i

    should.raise(Mustache::ContextMiss) {
      target "nothing"
      actual name: 'Bob' do
        div { :to_s }
      end
    }.message.should.match /Can't find \.html\(:to_s\)/i
  end

  it "raises ContextMiss when an unknown value is requested" do
    should.raise(Mustache::ContextMiss) {
      actual name: 'Bob' do
        div { :object_ids }
      end
    }.message.should.match /object_ids/
  end

  it "renders if inverted section and key is not defined" do
    target <<-EOF
      <div>hello</div>
    EOF

    actual {
      render_unless(:here) { div { 'hello' } }
    }
  end

  it "escapes html" do
    target <<-EOF
      <div>&amp; &#47; hello</div>
    EOF

    actual :hello=>'& / hello' do
      div { :hello }
    end
  end

  it "escapes html in nested values" do
    actual = WWW_App.new() {
      div.id(:my_box) {
        render_if(:hello) {
          span { :msg } 
          render_unless(:goodbye) {
            span { '&& hello 2' }
          }
        }
      }
    }.to_html(:hello=>{:msg=>'& hello 1', :goodbye=>nil})

    target = <<-EOF
      <div id="my_box"><span>&amp; hello 1</span>
        <span>&amp;&amp; hello 2</span></div>
    EOF

    norm_wo_lines(actual).should == norm_wo_lines(target)
  end

  it "escapes :href in nested values" do
    actual = WWW_App.new {
      div {
        render_if(:o) {
          div { a.href(:url) { :msg } }
        }
      }
    }.to_html(o: {url: '/hello', msg: 'hello'})
    target = %^<div><div><a href="&#47;hello">hello</a></div></div>^
    norm_wo_lines(actual).should == norm_wo_lines(target)
  end

  it "does not allow vars to be used in form :action" do
    should.raise(Escape_Escape_Escape::Invalid_Type) {
      actual :url=>'not allowed', :auth_token => 'hello' do
        form.action(:url) {}
      end
    }.message.should.match /:url/

  end

  it "does not allow vars to be used in :link :href" do
    should.raise(Escape_Escape_Escape::Invalid_Type) {
      actual(:hello=>'not_allowed') {
        link.href(:hello)./
      }
    }.message.should.match /:hello/
  end

  it "raises ContextMiss if encounters unescaped value" do
    should.raise(Mustache::ContextMiss) {
      actual(blue: 'hello<') {
        div { '-- {{{ blue }}}' }
      }
    }.message.should.match /blue/
  end

end # === describe Sanitize mustache ===





