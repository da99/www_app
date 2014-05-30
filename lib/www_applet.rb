
require "multi_json"

class WWW_Applet

  Error              = Class.new(RuntimeError)
  Invalid            = Class.new(Error)
  Value_Not_Found    = Class.new(Error)
  Computer_Not_Found = Class.new(Error)
  Too_Many_Values    = Class.new(Error)
  Value_Already_Created = Class.new(Error)
  Missing_Value      = Class.new(Error)

  class Computer

    attr_reader :name, :tokens, :origin

    def initialize name, tokens, origin
      @name   = name
      @tokens = tokens
      @origin = origin
    end

    def call calling_scope, name, args
      # eval the args
      forked = calling_scope.fork_and_run(name, args)

      # pass them to the computer
      c = WWW_Applet.new(tokens, origin)
      c.write_value "THE ARGS", origin.stack

      # run the computer from the origin scope
      c.run

      c.stack.last
    end

  end # === class Computer

  class << self
  end # === class self ===

  def initialize o, parent_computer = nil
    @vals   = {}
    @done   = false
    @stack  = []
    @parent = parent_computer
    @console = []
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

    write_computer "console print", lambda { |o, n, v|
      forked = o.fork_and_run(n, v)
      val = if forked.stack.size == 1
              forked.stack.last.inspect
            else
              forked.stack.inspect
            end
      top_parent_computer.console.push  val
      val
    }

    write_computer "+", lambda { |o,n,v|
      forked = o.fork_and_run(n,v)
      num1 = o.stack.last
      num2 = forked.stack.last
      num1 + num2
    }

    write_computer "value", lambda { |o,n,v|
      forked = o.fork_and_run(n,v)
      fail Too_Many_Values.new("#{n.inspect} #{v.inspect}") if forked.stack.size > 1

      raw_name = forked.stack.last
      fail Value_Not_Found.new(v.inspect) if !raw_name

      name = standard_key(raw_name)
      fail Value_Not_Found.new(name.inspect) if !values.has_key?(name)

      o.value name
    }

    write_computer "value =", lambda { |o,n,v|
      name   = o.stack.last
      forked = o.fork_and_run(n,v)
      fail Missing_Value.new("#{name.inspect} #{n.inspect} #{v.inspect}") if forked.stack.empty?

      o.write_value(name, forked.stack.last)
    }

    write_computer "computer =", lambda { |o,n,v|
      name = o.stack.last
      write_computer name, Computer.new(name, v, o)
      v
    }
  end

  def standard_key v
    v.strip.gsub(/\ +/, ' ').upcase
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

  def console
    @console
  end

  def object
    @obj
  end

  def code
    MultiJson.dump object
  end

  def value raw_name
    values[raw_name.strip.upcase]
  end

  def computers raw_name = :none
    if raw_name != :none
      return @funcs[raw_name.strip.upcase]
    end
    @funcs
  end

  def values
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

  def read_value raw_name
    @vals[standard_key(raw_name)]
  end

  def write_value raw_name, val
    name = raw_name.to_s.upcase
    fail Value_Already_Created.new(name) if values.has_key?(name)
    @vals[name] = val
    val
  end

  def write_computer raw_name, l
    name = raw_name.strip.upcase
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

      if val.is_a?(Array)
        fail Invalid.new("Computer name not specified: #{val.inspect}")
      end

      if next_val.is_a?(Array)
        curr += 1
        ruby_val = nil

        func_name = val.to_s.upcase

        funcs = computers(func_name)
        if !funcs && parent_computer
          funcs = parent_computer.computers(func_name)
        end

        fail Computer_Not_Found.new(val.inspect) if !funcs

        funcs.detect { |f|
          ruby_val = f.call(this_app, func_name, next_val)
          ruby_val != :cont
        }

        case ruby_val
        when :fin
          @done = true
        when :ignore_return
        when :cont
          fail Computer_Not_Found.new(val.inspect)
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
