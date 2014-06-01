
require "pry"
require "multi_json"

class WWW_Applet
  attr_reader :parent, :name, :tokens, :stack, :computers

  def initialize parent, name, tokens, args = nil
    @parent = parent
    @name   = standard_key(name || "__unknown__")
    @tokens = tokens
    @stack  = []
    @vals   = {}
    @args   = args || []

    @computers = {
      "COMPUTER ="         => "__create_computer__",
      "COPY OUTSIDE STACK" => "__copy_outside_stack__",
      "ENSURE ARGS"        => "__ensure_args__",
      "VALUE"              => "__read_value__"
    }

    write_value "THE ARGS", @args
  end

  def standard_key v
    v.strip.gsub(/\ +/, ' ').upcase
  end

  def fork_and_run name, tokens
    c = WWW_Applet.new(parent, name, tokens)
    c.run
    c
  end

  def __read_value__ sender, to, args
    val = read_value(args.last)
    sender.stack.push val
    val
  end

  def __ensure_args__ calling_scope, orig_calling_name, args
    the_args = calling_scope.read_value("THE ARGS")

    if args.length != the_args.length
      fail "Args mismatch: #{orig_calling_name.inspect} #{args.inspect} != #{the_args.inspect}"
    end

    args.each_with_index { |n, i|
      calling_scope.write_value n, the_args[i]
    }
    :none
  end

  def __copy_outside_stack__ sender, to, args
    target = sender.parent
    fail("Stack underflow in #{target.name.inspect} for: #{to.inspect} #{args.inspect}") if args.size > target.stack.size
    args.each_with_index { |a, i|
      write_value a, target.stack[target.stack.length - args.length - i]
    }
    :none
  end

  def __create_computer__ sender, to, tokens
    name   = standard_key(stack.last)
    fail("Computer already created: #{name.inspect}") if computers.has_key?(name)
    computers[name] = lambda { |sender, to, args|
      c = WWW_Applet.new(sender, to, tokens, args)
      c.run
      puts "COMPUTER run: #{to}"
    }
    puts "COMPUTER created: #{name.inspect}"
    :none
  end

  def read_value raw_name
    name = standard_key(raw_name)
    fail("Value does not exist: #{name.inspect}") unless @vals.has_key?(name)
    @vals[name]
  end

  def write_value raw_name, val
    name = standard_key(raw_name)
    fail("Value already created: #{name.inspect}") if @vals.has_key?(name)
    @vals[name] = val
    val
  end

  def run_computer sender, to, raw_args
    c = computers[standard_key(to)]
    fail("Computer not found: #{to}") unless c

    args = if standard_key(to) == standard_key("computer =")
             raw_args
           else
             sender.fork_and_run("arg run for #{to.inspect}", raw_args).stack
           end

    if c.respond_to? :call
      c.call(sender, to, args)
    else
      send(c, sender, to, args)
    end
  end

  def run
    start = 0
    stop  = tokens.length
    curr  = 0

    while curr < stop

      val              = tokens[curr]
      next_val         = tokens[curr + 1]
      is_end           = (curr + 1) == stop
      send_to_computer = next_val.is_a?(Array)

      if is_end || !send_to_computer
        stack.push val
      else # We send a message to a computer.
        curr += 1
        run_computer(self, val, next_val)
      end

      curr += 1

    end # while

    self
  end


end # === class Scope


tokens = MultiJson.load File.read("./lib/www_applet.json")
app    = WWW_Applet.new(nil, "__main__", tokens)
app.run

__END__



class WWW_Applet

  Error                 = Class.new(RuntimeError)
  Invalid               = Class.new(Error)
  Value_Not_Found       = Class.new(Error)
  Computer_Not_Found    = Class.new(Error)
  Too_Many_Values       = Class.new(Error)
  Value_Already_Created = Class.new(Error)
  Missing_Value         = Class.new(Error)


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
      c.write_value "THE ARGS", forked.stack

      # run the computer from the origin scope
      c.run

      c.stack.last
    end

  end # === class Computer

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
      @tokens  = MultiJson.load(o)
    else
      @code = MultiJson.dump(o)
      @tokens  = o
    end

    unless @tokens.is_a?(Array)
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

  def tokens
    @tokens
  end

  def code
    MultiJson.dump tokens
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
    i = @tokens.find_index(name)
    fail(Value_Not_Found.new name.inspect) unless i
    target = @tokens.delete_at(i)

    if @tokens[i].is_a?(Array)
      return @tokens.delete_at(i)
    end

    target
  end

  def read_value raw_name
    @vals[standard_key(raw_name)]
  end

  def write_value raw_name, val
    name = standard_key(raw_name)
    fail Value_Already_Created.new(name) if values.has_key?(name)
    @vals[name] = val
    val
  end

  def write_computer raw_name, l
    name = standard_key(raw_name)
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

    start    = 0
    fin      = @tokens.size
    curr     = start
    this_app = self

    while curr < fin && !@done
      val = @tokens[curr]
      next_val = @tokens[curr + 1]

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
