
describe :JS do

  it "renders js" do
    target :script, <<-EOF
      WWW_Applet.compile(
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

end # === describe :JS ===
