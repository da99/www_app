
describe :text do

  it "prints a string" do
    target :body, %^<p>string</p>^
    actual do
      p {
        text "string"
      }
    end
  end # === it prints a string if value is a hash: {:type=>:string, ...}

  it "prints a string passed to it as a single argument" do
    target :body, %^<p>string string</p>^
    actual do
      p "string string"
    end
  end # === it prints a string passed to it as a single argument

end # === describe "string content"

describe :raw_text do

  it "does not escape string" do
    target :body, %^<p>string & string</p>^
    actual do
      p {
        raw_text 'string & string'
      }
    end
  end # === it prints a string if value is a hash: {:type=>:string, ...}

end # === describe :raw_text
