
require "multi_json"
require "www_applet/Core"
require "www_applet/HTML"

class WWW_Applet

  attr_reader :parent, :name, :tokens, :stack, :values, :computers, :console

  MULTI_WHITE_SPACE = /\s+/
  VALID_NON_OBJECTS = [String, Fixnum, Float, TrueClass, FalseClass, NilClass]
  STOP_APPLET       = {"IS"=> ["APPLET COMMAND"], "VALUE"=>"STOP APPLET" }
  IGNORE_RETURN     = {"IS"=>"APPLET COMMAND", "VALUE"=>"IGNORE RETURN"}

  Computers = {
  }

  # ===================================================
  class << self
  # ===================================================

    def standard_key v
      v.strip.gsub(MULTI_WHITE_SPACE, ' ').upcase
    end

    def applet_command? val
      applet_object?(val) && val[:is].include?(:applet_command)
    end

    def applet_object? val
      val.is_a?(Hash) && val[:is].is_a?(Array)
    end

    def stack_able? val
      VALID_NON_OBJECTS.include?(val.class) ||
        (applet_object?(val) && !applet_command?(val))
    end

    def inspect_alias raw, actual
      raw_inspect = raw.inspect
      actual_inspect = actual.inspect
      if raw_inspect == actual_inspect
        raw_inspect
      else
        "#{raw_inspect} (as #{actual_inspect})"
      end
    end

    def include_computers mod

      namespace = Object.new
      namespace.extend mod

      mod::Meta.each { |raw_key, meta|

        name = case raw_key
               when String
                 standard_key(raw_key)
               when Symbol
                 standard_key(raw_key.to_s)
               else
                 fail "Invalid: computer name: #{raw_key.inspect}"
               end

        if self::Computers.has_key?(name)
          fail "Computer already exists: #{inspect_alias raw_key, name}"
        end

        self::Computers[name] = {
          :meta      => meta,
          :namespace => namespace
        }

      } # === .each Meta

      self

    end # === def include_computers

  end # === class =====================================

  include_computers Computers
  include_computers HTML

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

  end # def initialize

  def www
    ::WWW_Applet
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

  def grab_stack_tail num, msg
    if @stack.size < num
      fail("Invalid state: #{msg}")
    end

    if num == 1
      return @stack.pop
    end

    vals = []
    num.times do |i|
      vals.unshift @stack.pop
    end
    vals
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
        fail("Invalid value: #{val.inspect}") unless www.stack_able?(val)
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

          if www.stack_able?(resp) # === push value to stack
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
              fail("Invalid: Unknown operation: #{resp["VALUE"].inspect}")
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

  def run_computer
      unless ::WWW_APPLET::HTML_MODS_COMPILED[mod]
        HTML::VALUE_GROUPS.each { |group|
          if mod.const_defined?(group)
            mod.const_get(group).each { |tag, raw_meta|
              klass = HTML.const_get(group.to_s.sub(/s$/, '').to_sym)
              mod.instance_eval %^
              def #{tag} sender, to, raw_args
                new_html_value sender, to, raw_args, meta, ::WWW_Applet::HTML::COMPUTERS[:tag]
              end
              ^
              HTML::COMPUTERS[tag] = meta = {
                :name      => tag.to_s.sub(START_ON_REGEXP, '').gsub('_', '-'),
                :cleaners  => [],
                  :group_all => false,
                  :allow_in  => nil,
                  :klass     => klass
              }
              current = 0
              stop    = raw_meta.size
              while current < stop
                cmd = raw_meta[current]
                args = raw_meta[current+1]
                case cmd
                when :group_all
                  meta[:group_all] = true

                when :allow_in
                  current += 1
                  meta[:allow_in] = args

                when :tag
                  current += 1
                  meta[:name] = args
                  meta[:tag]  = args

                when :name
                  current += 1
                  meta[:name] = args

                when :attributes
                  current += 1
                  meta[:force_attributes] = args

                when :allowed_in
                  current += 1
                  result[:allowed_in] = args

                else
                  meta[:cleaners] << action
                end
                current += 1

              end
            } # each |tag, meta|
          end
        }
        ::WWW_APPLET::HTML_MODS_COMPILED[mod] = true
      end
  end # === def run_computer

end # === class WWW_Applet ================================================================






