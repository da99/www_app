
require "multi_json"

class WWW_Applet

  Invalid = Class.new(RuntimeError)

  class << self
  end # === class self ===

  attr_reader :code

  def initialize o
    case o
    when String
      @code = o
      @obj  = MultiJson.load(o)
    else
      @code = MultiJson.dump(o)
      @obj  = o
    end

    unless @obj.is_a?(Array)
      fail Invalid.new("JS object must be an array.")
    end
  end

end # === class WWW_Applet ===
