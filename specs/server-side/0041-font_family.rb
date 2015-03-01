
describe :font_family do

  it "allows commas: Tommy, Harry, Sally" do
    target :style, %^
      body {
        font-family: Ubuntu, Segoe UI, Helvetica, sans-serif;
      }
    ^
    actual {
      font_family "Ubuntu, Segoe UI, Helvetica, sans-serif"
    }
  end # === it allows commas: Tommy, Harry, Sally

end # === describe :font_family
