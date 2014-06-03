
require "multi_json"

class WWW_Applet

  attr_reader :parent, :name, :tokens, :stack, :values, :computers, :console
  MULTI_WHITE_SPACE = /\s+/
  VALID_NON_OBJECTS = [String, Fixnum, Float, TrueClass, FalseClass, NilClass]
  STOP_APPLET       = {"IS"=> ["APPLET COMMAND"], "VALUE"=>"STOP APPLET" }
  IGNORE_RETURN     = {"IS"=>"APPLET COMMAND", "VALUE"=>"IGNORE RETURN"}

  # ===================================================
  class << self
  # ===================================================

    def standard_key v
      v.strip.gsub(MULTI_WHITE_SPACE, ' ').upcase
    end

  end # === class =====================================

  # ===================================================
  # Instance methods:
  # ===================================================

  #
  # Possible:
  #
  #   new                        "[... JSON ...]"
  #   new                         [...tokens...]
  #   new            "__main__",  [...tokens...]
  #   new            "__main__", "[...tokens...]"
  #   new   applet , "my func" ,  [...tokens...]
  #   new   applet , "my func" ,  [...tokens...], [..args..]
  #
  def initialize *raw
    @console     = []
    @name        = nil
    @parent      = nil
    @tokens      = nil
    @args        = []
    @stack       = []
    @is_done     = false
    @is_running  = false
    @is_fork     = false
    @computers   = {}
    @values      = {
      "THE ARGS" => @args
    }

    case raw.length
    when 0
      fail "Invalid: Not enough arguments."
    when 1
      @name   = "origin"
      @tokens = raw.first
    when 2
      @name, @tokens = raw
    when 3
      @parent, @name, @tokens = raw
    when 4
      @parent, @name, @tokens, @args = raw
    else
      fail "Too many extra arguments: #{raw.inspect}"
    end

    @name = @name || "[unknown]"

    fail("Invalid value: for args: #{args.inspect}") unless @args.is_a?(Array)

    if @tokens.is_a?(String)
      @tokens = MultiJson.load @tokens
    end

    fail("Invalid: JS object must be an array") unless @tokens.is_a?(Array)

    self.extend(Computers) unless @parent
  end # def initialize

  def extend mod
    mod.public_instance_methods.each { |sym|
      name = if mod.respond_to?(:aliases) && mod.aliases[sym]
               standard_key(mod.aliases[sym])
             else
               standard_key(sym.to_s).gsub('_', ' ')
             end
      @computers[name] = [sym]
    }
    super
  end

  def standard_key *args
    self.class.standard_key(*args)
  end

  def applet_command? val
    applet_object?(val) && val["IS"].include?("APPLET COMMAND")
  end

  def applet_object? val
    val.is_a?(Hash) && val["IS"].is_a?(Array)
  end

  def stack_able? val
    VALID_NON_OBJECTS.include?(val.class) ||
      (applet_object?(val) && !applet_command?(val))
  end

  def fork? answer = :none
    if answer != :none
      @is_fork = answer
    end
    @is_fork
  end

  def fork_and_run name, tokens
    c = WWW_Applet.new(self, name, tokens)
    c.fork?(true)
    c.run
    c
  end

  def top
    p = parent
    curr = p
    while curr
      curr = p.parent
      p = curr if curr
    end
    p || self
  end

  def run
    fail("Invalid state: Already running.") if @is_running
    @is_running = true

    fail("Invalid state: Already finished running.") if @is_done

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
        fail("Invalid value: #{val.inspect}") unless stack_able?(val)
        stack.push val
        next
      end

      # ===================================================
      # SEND TO COMPUTER
      # ===================================================
      curr               += 1 # === move past the tokens array
      from                = self
      to                  = standard_key val
      raw_args            = next_val
      should_compile_args = (to != standard_key("IS A COMPUTER"))

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

        computers     = box.computers[to]
        computers_box = box

        box = box.parent
        next if !computers

        found = computers.detect { |c|

          resp = case
                 when c.respond_to?(:call) # it's a proc/lambda
                   c.call(from, to, args)
                 else                      # it's a String or Symbol
                   computers_box.send(c, from, to, args)
                 end

          if stack_able?(resp) # === push value to stack
            stack.push resp
            true

          else # === run applet command

            case resp["VALUE"]

            when "STOP APPLET"
              @is_done = true
              true

            when "IGNORE RETURN" # don't put anything on the stack
              true

            when "CONTINUE"
              false

            else
              fail("Invalid: Unknown operation: #{resp["VALUE"].to_s.inspect}")
              false

            end # case

          end # if

        } # === detect in Array of computers

      end # while box && !found

      fail("Computer not found: #{val.inspect}") unless found

      # ===================================================
      # END OF SEND TO COMPUTER
      # ===================================================

    end # while ===========================================

    @is_done = true
    self
  end # === def run


  # ============================================================================================
  # ============================================================================================
  # Module: Computers:
  # The base computers all other top parent computers have.
  # ============================================================================================
  # ============================================================================================
  module Computers

    def require_args sender, to, args
      the_args = sender.get("THE ARGS")

      if args.length != the_args.length
        fail "Args mismatch: #{to.inspect} #{args.inspect} != #{the_args.inspect}"
      end

      args.each_with_index { |n, i|
        sender.is n, the_args[i]
      }

      IGNORE_RETURN
    end

    def copy_outside_stack sender, to, args
      target = sender.parent
      fail("Stack underflow in #{target.name.inspect} for: #{to.inspect} #{args.inspect}") if args.size > target.stack.size
      args.each_with_index { |a, i|
        write_value a, target.stack[target.stack.length - args.length - i]
      }

      IGNORE_RETURN
    end

    def print sender, to, args
      val = if args.size == 1
              args.last.inspect
            else
              args.inspect
            end
      top.console.push val

      IGNORE_RETURN
    end

    def has_value? raw_name
      values.has_key?(standard_key(raw_name))
    end

    def get *raw
      if raw.size == 1 # runs as native method
        values[standard_key raw.last]
      else
        sender, to, args = raw
        name = standard_key args.last
        target = sender
        while (!target.values.has_key?(name) && target.fork? && target.parent)
          target = target.parent
        end

        fail("Value not found: #{name.inspect}") unless target.values.has_key?(name)
        target.values[name]
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
        raw_name   = sender.stack.pop
        fail("Missing value: #{raw_name.inspect} #{to.inspect} #{args.inspect}") unless raw_name

        name = standard_key raw_name
        fail("Missing value: #{name.inspect} #{to.inspect} #{args.inspect}") if args.empty?

        fail("Value already created: #{name.inspect}") if sender.values.has_key?(name)
        sender.values[name] = args.last
      end

      sender.values[name]
    end

    def is_a_computer sender, to, tokens
      raw_name = sender.stack.pop
      fail("Missing value: #{raw_name.inspect} #{to.inspect} [...tokens...]") unless raw_name
      name = standard_key(raw_name)
      sender.computers[name] ||= []
      sender.computers[name].push lambda { |sender, to, args|
        c = WWW_Applet.new(sender, to, tokens, args)
        c.run
        c.stack.last
      }

      {"IS"=> ["COMPUTER"], "VALUE"=> name}
    end

    def stop_applet sender, to, tokens
      STOP_APPLET
    end

  # ============================================================================================
  end # === module Computers
  # ============================================================================================
  # ============================================================================================


end # === class WWW_Applet ================================================================






