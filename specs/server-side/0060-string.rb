
describe "string content" do

  it "prints a string if value is a hash: {:type=>:string, ...}" do
    target :body, %^<p>string</p>^
    actual do
      p {
        {:type=>:string, :escape=>true, :value=>"string"}
      }
    end
  end # === it prints a string if value is a hash: {:type=>:string, ...}

  it "does not escape string if: {:type=>:string, :escape=>false...}" do
    target :body, %^<p>string & string</p>^
    actual do
      p {
        {:type=>:string, :escape=>false, :value=>"string & string"}
      }
    end
  end # === it prints a string if value is a hash: {:type=>:string, ...}

  it "raises an error if :type is not :string" do
    should.raise(WWW_App::Invalid_Type) {
      actual do
        p {
          {:type=>"uNkNown val", :escape=>false, :value=>"string & string"}
        }
      end
    }.message.should =~ /uNkNown/
  end # === it raises an error if :type is not :string

end # === describe "string content"
