
describe :script do

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

  it "can only have a relative url"

  it "escapes text as :html" do
    target :script, <<-EOF
      WWW_Applet.compile(
        ["create_event",["div","click","add_class",["red&lt;red"]]]
      );
    EOF

    actual do
      div {
        on(:click) { add_class "red<red" }
      }
    end
  end

  it "does not allow vars in :script :src attribute" do
    target :body, <<-EOF
      <script src="help"></script>
    EOF

    actual do
      script.src(:help)
    end
  end

  it "ignores text for :script block" do
    target %^<script src="&#47;hello.js"></script>^
    actual {
      script.src('/hello.js') { 'hello' }
    }
  end


end # === describe :JS ===
