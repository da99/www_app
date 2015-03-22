
describe :use do

  it "inserts another WWW_App inside" do
    nav = WWW_App.new {
      div.^(:nav_bar) {
        a.href('/') { 'Home' }
      }
    }

    target :body, <<-EOF
      <div id="main">
        <div class="nav_bar">
          <a href="&#47;">Home</a>
        </div>
      </div>
    EOF

    actual {
      div.id(:main) {
        use nav
      }
    }
  end # === it inserts another WWW_App inside

end # === describe :use
