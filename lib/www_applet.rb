
require "multi_json"

class WWW_Applet

  Invalid   = Class.new(RuntimeError)
  Not_Found = Class.new(RuntimeError)

  class << self
  end # === class self ===

  def initialize o
    @funcs = {}
    @done  = false
    @stack = []

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

  def stack o = nil
    if o
      @stack.concat o
    end
    @stack
  end

  def object
    @obj
  end

  def code
    MultiJson.dump object
  end

  def functions o = nil
    if o
      @funcs.merge! o
    end
    @funcs
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

  def write_function name, l
    @funcs[name] ||= []
    @funcs[name].push l
    l
  end

  def fork_and_run name, o
    forked = WWW_Applet.new o
    forked.functions functions
    forked.stack     stack
    forked.run
    forked
  end

  def run
    fail Invalid.new("Already finished running.") if @done

    start = 0
    fin   = @obj.size
    curr  = start
    this_app = self

    while curr < fin && !@done
      val = @obj[curr]
      next_val = @obj[curr + 1]
      if next_val.is_a?(Array)
        curr += 1
        ruby_val = nil
        functions[val].detect { |f|
          ruby_val = f.call(this_app, val, next_val)
          ruby_val != :cont
        }
        case ruby_val
        when :fin
          @done = true
        when :cont
          fail Invalid.new("Function not found: #{val}")
        else
          stack.push ruby_val
        end
      else
        stack.push val
      end

      curr += 1
    end

    @done = true
  end

end # === class WWW_Applet ===
