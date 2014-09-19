
describe :forms do

  it "requires a CSRF token" do
    should.raise(Mustache::ContextMiss) {
      actual do
        form.action('/home') {
        }
      end
    }.message.should.match /auth_token/
  end

  it "raises Invalid_Relative_HREF if :action is not a relative url" do
    should.raise(Escape_Escape_Escape::Invalid_Relative_HREF) {
      actual :auth_token => 'mytoken' do
        form.action('http://www.google.com/') {}
      end
    }.message.should.match /google.com/
  end

end # === describe :forms ===

