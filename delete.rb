
require 'ap'

class WWW_App

  attr_reader :tag, :tags
  def initialize
    @tags = []
    @tag  = nil
    create :body
    instance_eval &(Proc.new)
  end

  private def style *args
    case args.size

    when 0 # style { ... }
      create :styles
      create :group

    when 1 # style(:drowsy) { ... }
      create :style
      tag[:class] = args.first

    else
      fail ArgumentError, "Too many: #{args.inspect}"
    end

    yield self
    go_up
    close
    nil
  end

def debug *args
  return
  puts args.join(' -- ')
end

def go_up
  debug "--- going up #{@tag[:type]} -> #{@tag[:parent][:type]} #{caller(1, 1)}"
  @tag = @tag[:parent]
end

  %w{ a div }.each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name}
        go_up if in_a_group?
        if block_given?
          create(:#{name}) { yield }
        else
          create :#{name}
        end
      end
    EOF
  }

  %w[ link visited hover ].each { |name|
    eval %^
      def _#{name} *args
        if block_given?
          pseudo(:#{name}, *args) { yield }
        else
          pseudo :#{name}, *args
        end
      end
    ^
  }

  %w[ border color background_color p button ].each { |name|
    eval %^
      def #{name} *args
        self
      end
    ^
  }

  def pseudo name
    debug "--" + name.inspect
    tag[:pseudo] = name
    @tag[:closed] = true
    if block_given?
      close { yield }
    end
    self
  end

  def in_a_group?
    tag && tag[:parent] && tag[:parent][:type] == :group
  end

  def create name, opts = nil
    old = @tag
    new = {:type=>name}

    debug "CREATING: #{opts.inspect} #{name.inspect} in #{(@tag || {})[:type].inspect}"

    if old
      old[:children] ||= []
      old[:children] << new
      new[:parent] = old
    else
      @tags << new
    end

    @tag = new

    @tag.merge!(opts) if opts
    debug "created #{@tag[:type].inspect} in #{(@tag[:parent] || {} )[:type].inspect}"
    debug "FOCUS: #{@tag[:type]}"
    debug ""
    if block_given?
      close { yield }
    end
    self
  end

  def * arg
    tag[:id] = arg
    self
  end

  def / app
    debug "|| - closing #{@tag.inspect}"
    fail "No block allowed here." if block_given?
    @tag[:closed] = true
    self
  end

  def ^ *names
    tag[:class] ||= []
    tag[:class].concat names

    if block_given?
      close { yield }
    end
    self
  end

  def _
    fail "No block allowed here." if block_given?
    @tag[:closed] = true
    go_up
    self
  end

  def close
    if in_a_group?
      debug "closing #{@tag[:type]} in #{@tag[:parent][:type]}"
      @tag[:closed] = true
      go_up
      @tag[:proc] = Proc.new if block_given?
      @tag[:closed] = true
      go_up
      return create(:group)
    end

    if tag
      @tag[:closed] = true
      go_up
    end

    if @tag && @tag[:children]
      last = @tag[:children].last
      if last[:type] == :group && last[:children] && last[:children].empty?
        last[:children].pop
      end
    end

    self
  end

end # === class WWW_App

tags = WWW_App.new {

  style {

    div.*(:main)._.div.^(:drowsy) {
      border '1px dashed grey'
    }

    a._link / a._visited / a._hover { 
      color '#f88'
    }

    a {
      _link    { color '#fff' }
      _visited { color '#f88' }
      _hover   { color '#ccc' }
    }

  } # === style

  div.*(:main).^(:css_class_name) {

    border           '1px solid #000'
    background_color 'grey'

    style(:scary) {
      border           '2px dotted red'
      background_color 'white'
    }

    p { 'Click the button to make me scared.' }

    button {
      parent    'div'
      add_class :scary

      'Scary-ify'
    }

  }
}.tags

print %^
:body
  :styles
    :group
      div#main
      div.drowsy
    :group
      a :pseudo
      a :pseudo
      a :pseudo
    :group
      a :pseudo
      a :pseudo
      a :pseudo
  :div#main.css_class_name
  -----------------------------
^

def print t, indent = 0
  info = t.reject { |n|
    [:type, :parent, :children].include?( n )
  }
  puts "#{" ".freeze * indent}#{t[:type].inspect} -- #{info.inspect}"
  indent += 1
  if t[:children]
    t[:children].each { |c| print c, indent }
  end
end

indent = 0
tags.each { |t|
  print t
}
