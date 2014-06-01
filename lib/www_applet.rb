
require "multi_json"

class WWW_Applet

  attr_reader :parent, :name, :tokens, :stack, :values, :computers
  MULTI_WHITE_SPACE = /\s+/

  # ===================================================
  class << self
  # ===================================================

    def standard_key v
      v.strip.gsub(MULTI_WHITE_SPACE, ' ').upcase
    end

  end # === class

  # ===================================================
  # Instance methods:
  # ===================================================

  #
  # Possible:
  #
  #   new            "__main__", [...tokens...]
  #   new   applet , "my func" , [...tokens...]
  #   new   applet , "my func" , [...tokens...], [..args..]
  #
  def initialize *raw
    if raw.size == 2
      parent = nil
      name, tokens = raw
      args = nil
    else
      parent, name, tokens, args = raw
    end

    @parent    = parent
    @name      = standard_key(name || "__unknown__")
    @tokens    = tokens
    @stack     = []
    @is_done   = false
    @args      = args || []
    @values    = {}
    @computers = {}

    if !@parent
      extend Computers
      Computers.public_instance_methods.each { |n|
        @computers[standard_key(n.to_s)] = [n]
      }
    end

    is "THE ARGS", @args
  end

  def standard_key *args
    self.class.standard_key(*args)
  end

  def fork_and_run name, tokens
    c = WWW_Applet.new(parent, name, tokens)
    c.run
    c
  end

  def top
    p = parent_computer
    curr = p
    while curr
      curr = p.parent
      p = curr if curr
    end
    p
  end

  def run
    fail("Invalid state: Already finished running.") if @is_done
    start = 0
    stop  = tokens.length
    curr  = 0

    while curr < stop && !@is_done

      val              = tokens[curr]
      fail("Invalid syntax: Computer name not specified: #{val.inspect}") if val.is_a?(Array)
      next_val         = tokens[curr + 1]
      is_end           = (curr + 1) == stop
      should_send      = next_val.is_a?(Array)

      curr += 1

      if is_end || !should_send
        stack.push val
        next
      end

      # ===================================================
      # SEND TO COMPUTER
      # ===================================================
      curr               += 1 # === move past the token array
      from                = self
      to                  = standard_key val
      raw_args            = next_val
      should_compile_args = (to != standard_key("computer ="))

      args = if should_compile_args
               from.fork_and_run("arg run for #{to.inspect}", raw_args).stack
             else
               raw_args
             end

      # === Find the computer. ============================
      # === Send to computer. =============================
      # === Re-send to next computer if requested. ========
      # === Process final result. =========================
      box   = self
      found = nil
      while box && !found # == computer as box with array of computers

        found = computers[to].detect { |c|

          resp = case
                 when c.respond_to?(:call) # it's a proc/lambda
                   c.call(from, to, args)

                 else                      # it's a String or Symbol
                   send(c, from, to, args)
                 end


          if !resp.respond_to?(:call) # === not a native function
            stack.push resp
            true

          else # === run native function to see what to do next.

            resp = resp.call
            case resp

            when :exit_applet
              @is_done = true
              true

            when :ignore_return # don't put anything on the stack
              false

            when :cont
              false

            else
              fail("Invalid: Unknown operation: #{resp.to_s.inspect}")
              false

            end # case

          end # if

        } # === detect in Array of computers

        box = box.parent

      end # while box && !found

      fail("Computer not found: #{val.inspect}") unless found

      # ===================================================
      # END OF SEND TO COMPUTER
      # ===================================================

    end # while

    # === Mark it done
    @is_done = true

    # === The end
    self
  end # === def run


  # ============================================================================================
  # ============================================================================================
  # Module: Computers:
  # The base computers all other top parent computers have.
  # ============================================================================================
  # ============================================================================================
  module Computers

    def require_args calling_scope, orig_calling_name, args
      the_args = calling_scope.read_value("THE ARGS")

      if args.length != the_args.length
        fail "Args mismatch: #{orig_calling_name.inspect} #{args.inspect} != #{the_args.inspect}"
      end

      args.each_with_index { |n, i|
        calling_scope.write_value n, the_args[i]
      }
      :none
    end

    def copy_outside_stack sender, to, args
      target = sender.parent
      fail("Stack underflow in #{target.name.inspect} for: #{to.inspect} #{args.inspect}") if args.size > target.stack.size
      args.each_with_index { |a, i|
        write_value a, target.stack[target.stack.length - args.length - i]
      }
      :none
    end

    def print o, n, v
      forked = o.fork_and_run(n, v)
      val = if forked.stack.size == 1
              forked.stack.last.inspect
            else
              forked.stack.inspect
            end
      top_parent_computer.console.push  val
      val
    end

    def has_value? raw_name
      values.has_key?(standard_key(raw_name))
    end

    def value *raw
      if raw.size == 1 # runs as native method
        @values[standard_key raw.last]
      else
        sender, to, args = raw
        name = standard_key args.last
        fail("Value not found: #{name.inspect}") sender.values.has_key?(name)
        sender.values[name]
      end
    end

    def is *raw_args
      if raw_args.length == 2 # run as native function
        raw_name, val = raw_args
        name = standard_key raw_name
        fail("Value already created: #{name.inspect}") if @values.has_key?(name)
        @values[name] = val

      else
        sender, to, args = raw_args
        name   = standard_key sender.stack.last
        fail("Missing value: #{name.inspect} #{to.inspect} #{args.inspect}") if args.empty?

        fail("Value already created: #{name.inspect}") if sender.values.has_key?(name)
        sender.values[name] = args.last
      end

      name
    end

    def is_a_computer sender, to, tokens
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

  # ============================================================================================
  end # === module Computers
  # ============================================================================================
  # ============================================================================================


end # === class WWW_Applet ================================================================






