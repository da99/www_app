
describe :forms do

  it "requires a CSRF token" do
    should.raise(Mustache::ContextMiss) {
      actual do
        form.action('/home') {
        }
      end
    }.message.should.match /auth_token/
  end

end # === describe :forms ===

