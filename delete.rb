
class WWW_App

  NEW_LINE = "\n".freeze

  attr_reader :tag, :tags
  def initialize
    @tags = []
    @tag  = nil
    create :body
    instance_eval &(Proc.new)
  end

  def SPACE indent
    ' '.freeze * indent
  end

  private def style
  create :styles, :groups=>true
  close { yield }
  nil
  end

def debug *args
  puts args.join(' -- ')
end

def find_nearest name
  return @tag if @tag[:type] == name
  find_ancestor name
end

def find_ancestor name
  ancestor = @tag && @tag[:parent]
  while ancestor && ancestor[:type] != name
    ancestor = ancestor[:parent]
  end
  ancestor
end

def go_up_to_if_exists name
  target = find_ancestor name
  (@tag = target) if target
  self
end

def go_up_to name
  go_up_to_if_exists name
  fail "No parent found: #{name.inspect}" unless tag && tag[:type] == name
  self
end

def stay_or_go_up_to_if_exists name
  return self if @tag[:type] == name
  target = find_ancestor(name)
  (@tag = target) if target

  self
end

def stay_or_go_up_to name
  stay_or_go_up_to_if_exists name
  fail "No parent found: #{name.inspect}" unless tag && tag[:type] == name
  self
end

def go_up
  @tag = @tag[:parent]
end

  %w{ a div p button }.each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name}
        if block_given?
          create_tag(:#{name}) { yield }
        else
          create_tag(:#{name})
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

  %w[ border color background_color ].each { |name|
    eval <<-EOF, nil, __FILE__, __LINE__ + 1
      def #{name} *args
        css :#{name}, *args
      end
    EOF
  }

  def css name, *args
    @tag[:css] ||= {}
    @tag[:css][name] = args.join(', ')
    self
  end

  def parent name
    js :parent, [name]
  end

  def add_class *classes
    js :add_class, classes.flatten
  end

  def js func, args
    @tag[:js] ||= []
    @tag[:js] << [func, args]
    self
  end

  def pseudo name
    case
    when tag[:closed]
      create :group
      create :__

    when tag[:pseudo] && !tag[:closed]
      go_up_to :group
      create :__

    end # === case

    tag[:pseudo] = name
    if block_given?
      close { yield }
    end
    self
  end

  def in_a_group?
    !!( (@tag && @tag[:type] == :group) || find_ancestor(:group) )
  end

  def parent_tag
    tag && tag[:parent]
  end

  def create_tag name
    if tag && tag[:groups]
      create :group
    else
      stay_or_go_up_to_if_exists(:group) if tag && !tag[:_]
    end

    if block_given?
      create(name) { yield }
    else
      create(name)
    end
    self
  end

  def create name, opts = nil
    old = @tag
    new = {:type=>name}

    if old
      old[:children] ||= []
      old[:children] << new
      new[:parent] = old
    else
      @tags << new
    end

    @tag = new

    @tag.merge!(opts) if opts
    if block_given?
      close { yield }
    end
    self
  end

  def * arg
    tag[:id] = arg
    close { yield } if block_given?
    self
  end

  def / app
    fail "No block allowed here." if block_given?
    self
  end

  def ^ *names
    tag[:class] ||= []
    tag[:class].concat names

    close { yield } if block_given?
    self
  end

  def _
    case
    when tag[:type] == :group
      create :_
    when tag[:groups]
      create :group
      create :_
    else
      tag[:_] = true
    end

    self
  end

  def close
    group = find_nearest(:group)
    if group
      stay_or_go_up_to :group
      final_parent = parent_tag

      # We set :groups=>true because
      # we want tags created in the block to create their own
      # group as a child element.
      @tag[:groups] = true

      @tag[:closed] = true
      yield
      @tag = final_parent
      return self
    end

    @tag[:closed] = true
    final_parent = parent_tag
    yield if block_given?
    @tag = final_parent

    self
  end # === close

  HTML_TAGS = %w{ body div p a button }.map(&:to_sym)

  def to_raw_text
    str    = ""
    indent = 0
    print_tag = lambda { |t|
      info      = t.reject { |n| [:type, :parent, :children].include?( n ) }

      str += "#{" " * indent}#{t[:type].inspect} -- #{info.inspect}\n"
      indent += 1
      if t[:children]
        t[:children].each { |c|
          str << print_tag.call(c)
        }
      end
      indent -= 1
    }

    tags.each { |t| print_tag.call(t) }
    str
  end

  def to_html
    final  = ""
    indent = 0
    todo   = @tags.dup
    last   = nil

    while !todo.empty?
      tag = todo.shift
      case

      when tag == :new_line
        final << NEW_LINE

      when tag == :open
        unless indent.zero?
          final << NEW_LINE << SPACE(indent)
        end
        final << "<#{todo.shift}>"
        last = indent
        indent += 2

      when tag == :close
        indent -= 2
        if last != indent
          final << SPACE(indent)
        end
        last = indent
        final << "</#{todo.shift}>"

      when HTML_TAGS.include?(tag[:type])

        new_todo = [:open, tag[:type]]

        if tag[:children]
          new_todo.concat tag[:children]
          new_todo << :new_line
        end
        new_todo.concat [:close, tag[:type]]
        todo = new_todo.concat(todo)

      when tag[:type] == :style || tag[:type] == :styles
        todo = [:open, tag[:type], :close, tag[:type]].concat(todo)

      else
        fail "Unknown: #{tag.inspect}"
      end # === case
    end # === while

    final
  end # === to_html

end # === class WWW_App

app = WWW_App.new {

  style {

    div.*(:main)._.div.^(:drowsy) / a.^(:excited)._link {
      border '1px dashed grey'
      div.^(:mon) / div.^(:tues) {
        border '1px dashed weekday'
      }
    }

    a._link / a._visited / a._hover {
      color '#f88'
    }

    a {
      _link / _visited  { color '#fff' }
      _hover            { color '#ccc' }
    }

  } # === style

  div.*(:main).^(:css_class_name) {

    border           '1px solid #000'
    background_color 'grey'

    style {
      a._link / a._visited {
        color '#fig'
      }

      _.^(:scary) {
        border           '2px dotted red'
        background_color 'white'
      }
    }

    p { 'Click the button to make me scared.' }

    button {
      parent    'div'
      add_class :scary

      'Scary-ify'
    }

  }
}

tags = app.tags

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
    :group
      a
        :group
          __.link
          __.visited
        :group
          __.hover
  :div#main.css_class_name
  -----------------------------
^

puts app.to_raw_text
puts "====="
puts app.to_html
