
file_name = "./proof.rb"
content = File.read(file_name)


module HTML

  def init
    @title  = nil
    @style  = {}
    @parent = nil
    @dom    = []
  end

  def title string
    @title = string
  end

  def style h
    @style = h
  end

  %w[ p form button splash_line div ].each { |tag|
    eval %^
      def #{tag} attr, &blok
        new_tag :#{tag}, attr, &blok
      end
    ^
  }

  def new_tag tag, attr
    e = {:tag=>tag, :attr=> nil, :text=>nil, :childs=>[]}

    case attr
    when String
      e[:text] = attr
    when Hash
      e[:attr] = attr
    end

    if @parent
      @parent[:childs] << e
      e[:parent] = @parent
    else
      @dom << e
    end

    @parent = e

    if block_given?
      result = yield
      if result.is_a? String
        e[:text] = result
      end
    end

    @parent = e[:parent]
    e[:parent] = nil
  end

  def to_html e = nil
    require "pp"
    pp @dom
  end

end # === module HTML ===

klass = Class.new {
  include HTML

  code = %^
    def initialize
      init
      #{content}
    end
  ^
  eval code.strip, nil, file_name, -1
}

puts "======================"
o = klass.new
puts "======================"
o.to_html

