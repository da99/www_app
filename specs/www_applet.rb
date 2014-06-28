
require "differ"
Differ.format = :color

def fragment &blok
  WWW_Applet.new(&blok).to_html
end

def should_equal actual, target
  a = norm(actual)
  t = norm(target)
  if a != t
    puts " ======== ACTUAL =========="
    puts a
    puts " ======== TARGET =========="
    puts t
    puts " =========================="
    puts Differ.diff_by_word(a,t)
    fail "No match"
  else
    a.should == t
  end
end

describe "WWW_Applet:" do

  describe ".to_html" do

    it "produces links" do
      actual = fragment {
        a('/here' ) { "Here" }
      }
      should_equal actual, %^<a href="/here">Here</a>^
    end

  end # === describe WWW_Applet.new ===

end # === describe Ruby specific




