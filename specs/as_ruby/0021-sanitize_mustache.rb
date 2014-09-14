
describe "Sanitize mustache" do

  it "escapes html" do
    target <<-EOF
      <div>&amp; &#47; hello</div>
    EOF

    actual :hello=>'& / hello' do
      div { :hello }
    end
  end

  it "escapes html in nested values" do
    target <<-EOF
      <div id="my_box"><span>&amp; hello 1</span>
        <span>&amp;&amp; hello 2</span></div>
    EOF

    actual(:hello=>{:msg=>'& hello 1', :goodbye=>nil}) {
      div.*(:my_box) {
        render_if(:hello) {
          span { :msg } 
          render_unless(:goodbye) { span { '&& hello 2' } }
        }
      }
    }
  end

end # === describe Sanitize mustache ===



