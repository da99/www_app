
require "multi_json"

class WWW_Applet

  Invalid            = Class.new(RuntimeError)
  Value_Not_Found    = Class.new(RuntimeError)
  Computer_Not_Found = Class.new(RuntimeError)

  class << self
  end # === class self ===

  def initialize o, parent_computer = nil
    @vals   = {}
    @done   = false
    @stack  = []
    @parent = parent_computer
    @funcs  = {}

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

    write_function "console print", lambda { |o, n, v|
      top_computer.console.push v.inspect
    }

    write_function  "value =", lambda { |o,n,v|
      name = o.stack.last.strip.upcase
      fork = o.fork_and_run(n,v)
      val = fork.stack.last
      o.values[name] = val
    }
  end

  def top_parent_computer
    p = parent_computer
    curr = p
    while curr
      curr = p.parent_computer
      p = curr if curr
    end
    p
  end

  def parent_computer
    @parent
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
    @funcs.merge!(o) if o
    @funcs
  end

  def value name
    values[name.strip.upcase]
  end

  def values o = nil
    @vals.merge!(o) if o
    @vals
  end

  #
  # Note: Case sensitive
  #
  def extract_first name
    i = @obj.find_index(name)
    fail(Value_Not_Found.new name.inspect) unless i
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
    forked = WWW_Applet.new o, self
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

        funcs = functions[val]
        if !funcs && parent_computer
          funcs = parent_computer.functions[val]
        end

        fail Computer_Not_Found.new(val.inspect) if !funcs

        funcs.detect { |f|
          ruby_val = f.call(this_app, val, next_val)
          ruby_val != :cont
        }
        case ruby_val
        when :fin
          @done = true
        when :ignore_return
        when :cont
          fail Invalid.new("Function not found: #{val}")
        when Symbol
          fail Invalid.new("Unknown operation: #{ruby_val.inspect}")
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
