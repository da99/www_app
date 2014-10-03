
class WWW_App
  class Clean

    attr_reader :name, :origin, :actual

    def initialize name, val
      @name   = name[" "] ? name : name.inspect
      @origin = val
      @actual = val
    end

    def update val
      @actual = val
    end

    #
    # Examples:
    #
    #   clean_as :upcase, :string, :in, [1,2,3]
    #   clean_as :upcase, :string, :switch, {...}
    #
    def clean_as *args
      begin
        cleaner = args.shift
        case
        when args.first.is_a?(Array)
          send cleaner, *(args.shift)
        when args.first.is_a?(Hash)
          send cleaner, args.shift
        else
          send cleaner
        end
      end while !args.empty?

      self
    end

    def not_nil
      if actual.nil?
        fail "Invalid: #{name} is required."
      end

      self
    end

    def string
      return self if actual.is_a?(String)
      fail "Invalid: #{name} must be a String: #{actual.inspect}"
    end

    def number
      return self if actual.is_a?(Numeric)
      fail "Invalid: #{name} must be a Number: #{actual.inspect}"
    end

    def not_empty_string
      string
      update actual.strip
      if actual.empty?
        fail "Invalid: #{name} must not be empty."
      end

      self
    end

    def downcase
      not_empty_string
      update actual.downcase

      self
    end

    def upcase
      not_empty_string
      update actual.upcase

      self
    end

    def color
      not_empty_string
      if !(actual =~ /\A#[A-Z0-9]{3,10}\Z/i)
        fail "Invalid: color for #{name}: #{origin.inspect}."
      end

      self
    end

    def max_length max, msg = nil
      not_nil
      if actual.length > 200
        fail(msg || "#{name} can not be more than #{max}")
      end

      self
    end

    def match regex, msg = nil
      string
      if !(actual =~ regex)
        fail(msg || "Invalid: #{name} has invalid chars")
      end

      self
    end

    VALID_URL_REGEXP = /\A[a-z0-9\_\-\:\/\?\&\(\)\@\.]{1,200}\Z/i
    def url
      max = 200
      not_empty_string
      max_length max, "#{name} needs to be #{max} or less chars."
      match VALID_URL_REGEXP

      self
    end

    def in *raw
      choices = raw.flatten
      if !choices.include?(actual)
        fail "Invalid: #{name} can't be, #{actual.inspect}, but one of: #{choices.join ", "}"
      end

      self
    end

    def switch choices
      self.in(choices.keys)
      update choices[actual]

      self
    end

    def map action, *args
      update(
        actual.map { |v|
          Clean.new("#{name} value", v).
            send(action, *args).
            actual
        }
      )

      self
    end

    def number_between min, max
      number
      if actual < min || actual > max
        fail "Invalid: #{name}, #{actual.inspect}, must be between: #{min} and #{max}"
      end

      self
    end

    # ================= HTML-specific =====================================================

    VALID_FONT_REGEXP = /\A[a-z0-9\-\_\ ]{1,100}\Z/i

    def fonts
      map :not_empty_string
      map :match, VALID_FONT_REGEXP, "only allow 1-100 characters: letters, numbers, spaces, - _"

      self
    end

    # =====================================================================================

  end # === class Clean
end # === class WWW_App
