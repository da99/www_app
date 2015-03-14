
describe "HTML :on" do

  it "escapes text as :html" do
    target :script, <<-EOF
    EOF

    actual = WWW_App.new do
      div.id(:main) {
        on(:click) { add_class "red<red" }
      }
    end.to_html

    actual.scan(%r!<script type="application/javascript">([^<]+)</script>!).flatten.map { |s| norm_wo_lines(s) }.
      should == [norm_wo_lines(%^
      WWW_App.compile(
        ["#main","on",["click"],["add_class",["red&lt;red"]]]
      );^)]
  end

  it "renders js" do
    target = norm_wo_lines <<-EOF
      WWW_App.compile(
        #{
          Escape_Escape_Escape.json_encode( ["#my_box", "on", ["click"], ["add_class", ["hello"] ] ] )
        }
      );
    EOF

    actual = WWW_App.new {
      div.id(:my_box) {
        on(:click) { add_class :hello }
      }
    }.to_html[%r!<script type="application/javascript">([^<]+)</script>!]

    norm_wo_lines($1).should == target
  end

end # === describe


