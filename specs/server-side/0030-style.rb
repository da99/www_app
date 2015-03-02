
describe "css pseudo" do

  %w[link visited hover].each { |name|
    it "adds :#{name} pseudo-class" do
      target :style, <<-EOF
        a:#{name} {
          color: #fff;
        }
      EOF

      actual do
        a {
          send("_#{name}".to_sym) { color '#fff' }
        }
      end
    end # === it
  }

end # === describe "css pseudo"
