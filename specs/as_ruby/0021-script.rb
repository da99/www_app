
describe :script do

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

  it "raises Invalid_Relative_HREF if :src is not relative" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual do
        script.src('http://www.example.org/file.js')./
      end
    }.message.should.match /example\.org/
  end

  it "allows a relative :src" do
    target %^<script src="&#47;file.js"></script>^
    actual {
      script.src('/file.js')./
    }
  end

  it "escapes slashes in attr :src" do
    target %^<script src="&#47;dir&#47;file.js"></script>^
    actual {
      script.src('/dir/file.js')./
    }
  end

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
