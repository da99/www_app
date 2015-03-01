
describe "HTML :on" do

  it "escapes text as :html" do
    target :script, <<-EOF
      WWW_App.compile(
        ["create_event",["div","click","add_class",["red&lt;red"]]]
      );
    EOF

    actual do
      div {
        on(:click) { add_class "red<red" }
      }
    end
  end

  it "renders js" do
    target :script, <<-EOF
      WWW_App.compile(
        #{
          Escape_Escape_Escape.json_encode( ["create_event", [ "#my_box", "click", "add_class", ["hello"] ] ] )
        }
      );
    EOF

    actual {
      div.*(:my_box) {
        on(:click) { add_class :hello }
      }
    }
  end

  it "adds class to id of element: #id.class" do
    target :style, %^
      #me.highlight {
        border-color: #fff;
      }
    ^

    actual do
      div.*(:me) {
        on(:highlight) { border_color '#fff' }
      }
    end
  end

  it "adds a psuedo class if passed a String" do
    target :style, <<-EOF
      a:hover {
        border: 12px;
      }
    EOF

    actual {
      a.href('/home') {
        on(':hover') { border '12px' }
      }
    }
  end

end # === describe


