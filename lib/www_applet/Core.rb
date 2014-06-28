
class WWW_Applet

  # ============================================================================================
  # The base computers all other top parent computers have.
  # ============================================================================================
  module Core


    IGNORE_RETURN = {:is=>[:applet_command], :value=>:ignore_return}

    class << self
      def is_native name
        Computers[name] = [:run_native, [ name ]]
      end
    end # === class self ===

    Computers = {
      :stop_applet => [:applet_command, [:stop_applet]],
      :ignore_return => [:applet_command, [:ignore_return]]
    }

    is_native def applet_command sender, to, args
      {:is=>[:applet_command], :value=>args.last}
    end

    is_native def require_args sender, to, args
      the_args = sender.get("THE ARGS")

      if args.length != the_args.length
        fail "Args mismatch: #{to.inspect} #{args.inspect} != #{the_args.inspect}"
      end

      args.each_with_index { |n, i|
        sender.is n, the_args[i]
      }

      IGNORE_RETURN
    end

    is_native def copy_outside_stack sender, to, args
      target = sender.parent
      if args.size > target.stack.size
        fail("Stack underflow in #{target.name.inspect} for: #{to.inspect} #{args.inspect}")
      end
      args.each_with_index { |a, i|
        sender.is a, target.stack[target.stack.length - args.length - i]
      }

      IGNORE_RETURN
    end

    is_native def print sender, to, args
      val = if args.size == 1
              args.last.inspect
            else
              args.inspect
            end
      top.console.push val

      IGNORE_RETURN
    end

    def has? *raw
      if raw.length == 1 # run as native function
        values.has_key?(standard_key(raw.first))
      else
        sender, to, args = raw
        fail "Not done"
      end
    end

    is_native def get *raw
      if raw.size == 1 # runs as native function
        return values[standard_key raw.last]
      end

      sender, to, args = raw
      name   = standard_key args.last
      target = sender
      while (!target.values.has_key?(name) && target.fork? && target.parent)
        target = target.parent
      end

      fail("Value not found: #{name.inspect}") unless target.values.has_key?(name)
      target.values[name]
    end

    is_native def is *raw_args
      if raw_args.length == 2 # run as native function
        raw_name, val = raw_args
        name = standard_key(raw_name)
        if @values.has_key?(name)
          fail "Value already created: #{raw_name.inspect}"
        end
        @values[name] = val
        return val
      end

      sender, to, args = raw_args
      raw_name = sender.stack.pop
      value    = args.last
      source = "#{raw_name.inspect} #{to.inspect} #{args.inspect}"
      if !raw_name
        fail "Missing value: #{source}"
      end

      if !(raw_name.is_a? String)
        fail "Invalid value: Must be a string: #{source}"
      end

      if args.empty?
        fail "Missing value: #{source}"
      end

      name = standard_key raw_name
      if sender.values.has_key?(name)
        fail("Value already created: #{name.inspect}")
      end

      sender.values[name] = value
      value
    end

    is_native def is_a_computer sender, to, tokens
      source   = "#{sender.stack.last.inspect} #{to.inspect} [...]"
      if sender.stack.empty?
        fail("Missing value: a name for the computer: #{source}")
      end

      raw_name = sender.stack.pop
      if !raw_name.is_a?(String)
        fail "Invalid value: computer name must be a string: #{source}"
      end

      name = standard_key(raw_name)
      if sender.computers[name]
        fail "Invalid value: computer name already taken: #{source}"
      end

      sender.computers[name] = [
        lambda { |sender, to, args|
          c = WWW_Applet.new(sender, "SEND TO: #{to.inspect}", tokens, args)
          c.run
          c.stack.last
        }
      ]

      {:is=> [:computer], :value=> name}
    end


  end # === module Computers
end # === class WWW_Applet





