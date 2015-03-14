
describe "HTML :on" do

  it "escapes text as :html" do
    target :script, <<-EOF
      WWW_App.compile(
        ["#main","on",["click"],["add_class",["red&lt;red"]]]
      );
    EOF

    actual do
      div.id(:main) {
        on(:click) { add_class "red<red" }
      }
    end
  end

  it "renders js" do
    target :script, <<-EOF
      WWW_App.compile(
        #{
          Escape_Escape_Escape.json_encode( ["#my_box", "on", ["click"], ["add_class", ["hello"] ] ] )
        }
      );
    EOF

    actual {
      div.id(:my_box) {
        on(:click) { add_class :hello }
      }
    }
  end

end # === describe


