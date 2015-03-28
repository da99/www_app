
describe :heading_tags do

  [:h1, :h2, :h3, :h4].each { |meth|
    it "renders a :#{meth} tag" do
      target :body, <<-EOF
        <#{meth}>Title</#{meth}>
      EOF

      actual {
        send(meth) { 'Title' }
      }
    end # === it renders a .... tag

    it "accepts a String argument" do
      target :body, <<-EOF
        <#{meth}>Title Title</#{meth}>
      EOF

      actual {
        send(meth, 'Title Title')
      }
    end # === it accepts a String argument
  }

end # === describe :heading_tags
