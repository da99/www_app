
describe :JS do

  it "renders js" do
    target :script, <<-EOF
      WWW_Applet.compile(
        #{
          MultiJson.dump( ["create_event", [ "#my_box", "click", "add_class", ["hello"] ] ], pretty: true)
        }
      );
    EOF

    actual {
      div.*(:my_box) {
        on(:click) { add_class :hello.to_s }
      }
    }
  end

end # === describe :JS ===
