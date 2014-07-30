
describe "HTML" do

  it "escapes chars in 'href' attributes" do
    actual = input [
      "a", [
        "href", ["& & &"],
        "home"
      ]
    ]

    target = to_doc %^<a href="&amp;%20&amp;%20&amp;">home</a>^

    should_eq actual, target
  end

  it "escapes :href" do
    target %^<a href="&amp;%20&amp;%20&amp;">Escape</a>^

    actual do
      a(:href=>'& & &') { "Escape" }
    end
  end

  it "escapes inner text" do
    target %^<p>&amp; here lies jackie</p>^

    actual do
      p { "& here lies jackie" }
    end
  end

end # === describe HTML ===


describe "Style" do

  it "sanitizes urls"

  it "removes 'expression:'"

end # === describe Style ===






