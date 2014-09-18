

describe "IS_DEV" do

  before {
    @orig = ENV['IS_DEV']
  }

  after {
    ENV['IS_DEV'] = @orig
  }

  it "raises RuntimeError if passed a block and non-IS_DEV" do
    should.raise(RuntimeError) {
      ENV['IS_DEV'] = nil
      WWW_Applet.new {
        div {}
      }
    }.message.should.match /non-DEV/i
  end

end # === describe IS_DEV ===

