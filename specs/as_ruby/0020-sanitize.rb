
describe "Sanitize" do

  it "escapes chars in 'href' attributes" do
    target = %^<a href="&amp;%20&amp;%20&amp;">home</a>^

    actual do
      a(:href=>'& & &') { "home" }
    end
  end

  it "escapes inner text" do
    target %^<p>&amp; here lies jack</p>^

    actual do
      p { "& here lies jack" }
    end
  end

end # === describe HTML ===


describe "Style" do

  it "sanitizes urls"

  it "removes 'expression:'"

end # === describe Style ===






