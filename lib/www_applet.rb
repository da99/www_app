
require "multi_json"

class WWW_Applet

  Invalid   = Class.new(RuntimeError)
  Not_Found = Class.new(RuntimeError)

  class << self
  end # === class self ===

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

  def object
    @obj
  end

  def code
    MultiJson.dump object
  end

  #
  # Note: Case sensitive
  #
  def extract_first name
    i = @obj.find_index(name)
    fail(Not_Found.new "value: #{name}") unless i
    target = @obj.delete_at(i)

    if @obj[i].is_a?(Array)
      return @obj.delete_at(i)
    end

    target
  end

end # === class WWW_Applet ===
