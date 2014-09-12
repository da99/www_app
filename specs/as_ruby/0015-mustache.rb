
describe :mustache do

  it "replaces values with hash" do
    target <<-EOF
      <div>hello</div>
    EOF

    actual greeting: 'hello' do
      div { :greeting }
    end
  end

end # === describe :mustache
