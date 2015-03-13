require 'mustache'
require 'escape_escape_escape'

# ===================================================================
# === Symbol customizations: ========================================
# ===================================================================
class Symbol

  def to_mustache meth
    WWW_App::Clean.mustache meth, self
  end

end # === class Symbol
# ===================================================================

# ===================================================================
# === Mustache customizations: ======================================
# ===================================================================
Mustache.raise_on_context_miss = true

class Mustache

  def render(data = template, ctx = {})
    ctx = data
    tpl = templateify(template)

    begin
      context.push(ctx)
      tpl.render(context)
    ensure
      context.pop
    end
  end # === def render

  class Generator

    alias_method :w_syms_on_fetch, :on_fetch

    def on_fetch(names)
      if names.length == 2
        "ctx[#{names.first.to_sym.inspect}, #{names.last.to_sym.inspect}]"
      else
        w_syms_on_fetch(names)
      end
    end

  end # === class Generator

  class Context

    def find *args
      fail "No longer needed."
    end

    alias_method :[], :fetch
    def fetch *args
      raise ContextMiss.new("Can't find: #{args.inspect}") if args.size != 2

      meth, key = args

      @stack.each { |frame|
        case
        when frame.is_a?(Hash) && meth == :coll && !frame.has_key?(key)
          return false

        when frame.is_a?(Hash) && meth == :coll && frame.has_key?(key)
            target = frame[key]
            if target == true || target == false  || target == nil || target.is_a?(Array) || target.is_a?(Hash)
              return target
            end
            fail "Invalid value: #{key.inspect} (#{key.class})"

        when frame.is_a?(Hash) && frame.has_key?(key)
          return ::Escape_Escape_Escape.send(meth, frame[key])

        end
      }

      raise ContextMiss.new("Can't find .#{meth}(#{key.inspect})")
    end

  end # === class Context

end # === class Mustache
# ===================================================================

class WWW_App

  class Clean

    MUSTACHE_Regex = /\A\{\{\{? [a-z0-9\_\.]+ \}\}\}?\z/i

    class << self

      def mustache *args
        meth, val = args
        if val.is_a?(Symbol)
          m = "{{{ #{meth}.#{val} }}}"
          fail "Unknown chars: #{args.inspect}" unless m[MUSTACHE_Regex]
        else
          m = ::Escape_Escape_Escape.send(meth, val)
        end
        m
      end

      def method_missing name, *args
        if args.last.is_a?(::Symbol)
          args.push(args.pop.to_s)
        end
        ::Escape_Escape_Escape.send(name, *args)
      end

    end # === class << self
  end # === class Clean

  module TO
    COMMA   = ", ".freeze
    SPACE   = " ".freeze
    NOTHING = "".freeze

    KEY_REQUIRED = proc { |hash, k|
      fail "Key not set: #{k.inspect}"
    }

    def to_raw_text
      str    = ""
      indent = 0
      print_tag = lambda { |t|
        info          = t.select { |n| [:id, :class, :closed, :pseudo].include?( n ) }
        info[:parent] = t[:parent] && t[:parent][:tag_name]

        str += "#{" " * indent}#{t[:tag_name].inspect} -- #{info.inspect.gsub(/\A\{|\}\Z/, '')}\n"
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

    def to_html *args
      return @mustache.render(*args) if instance_variable_defined?(:@mustache)

      final  = ""
      indent = 0
      todo   = @tags.dup
      last   = nil
      stacks = {}

      doc = [
        (doc_type = {:tag_name=>:doc_type, :text=>"<!DOCTYPE html>"}),
        (html          = {:tag_name=>:html, :children=>[
          (head        = {:tag_name=>:head, :lang=>'en', :children=>[
          ]}),
          (body     = {:tag_name=>:body, :children=>[]})
        ]})
      ]

      style_tags = {:tag_name=>:style_tags, :children=>[]}

      tags = @tags.dup
      while (t = tags.shift)
        t_name = t[:tag_name]
        parent = t[:parent]

        case # ==============
        when t_name == :title && !parent
          head[:children] << t

        when t_name == :meta
          head[:children] << t

        when t_name == :title
          fail "Title already set." if head[:children].detect { |c| c[:tag_name] == :title }
          head[:children] << t

        when t_name == :style
          style_tags[:children] << t

        when t_name == :_ && !parent
          body[:css] = (body[:css] || []).concat(t[:css]) if t[:css]
          body[:class] = (body[:class] || []).concat(t[:class]) if t[:class]

          if t[:id]
            fail ":body already has id: #{body[:id].inspect}, #{t[:id]}" if body[:id]
            body[:id]  = t[:id] 
          end

          if t[:children]
            body[:children].concat t[:children]
            tags = t[:children].dup.concat(tags)
          end

        else # ==============
          if !parent
            body[:children] << t
          end

          if t[:css]
            style_tags[:children] << t
          end

          if t[:children]
            tags = t[:children].dup.concat(tags)
          end

        end # === case ========
      end # === while

      head[:children] << style_tags

      content_type = head[:children].detect { |t| t[:tag_name] == :meta && t[:http_equiv] && t[:http_equiv].downcase=='Content-Type'.downcase }
      if !content_type
        head[:children].unshift(
          {:tag_name=>:meta, :http_equiv=>'Content-Type', :content=>"text/html; charset=UTF-8"}
        )
      end

      todo = doc.dup
      while (tag = todo.shift)
        t_name = tag.is_a?(Hash) && tag[:tag_name]

        case

        when tag == :new_line
          final << NEW_LINE

        when tag == :open
          attributes = stacks.delete :attributes

          unless indent.zero?
            final << NEW_LINE << SPACES(indent)
          end

          tag_sym = todo.shift

          if attributes
            final << "<#{tag_sym} #{attributes}>"
          else
            final << "<#{tag_sym}>"
          end

          last = indent
          indent += 2

        when tag == :close
          indent -= 2
          if last != indent
            final << SPACES(indent)
          end
          last = indent
          final << "</#{todo.shift}>"

        when tag == :clean_attrs
          attributes = todo.shift
          target     = todo.shift

          attributes.each { |attr, val|
            attributes[attr] = case

                               when attr == :href && target[:tag_name] == :a
                                 Clean.mustach :href, val

                               when [:action, :src, :href].include?(attr)
                                 Clean.relative_href(val)

                               when attr == :id
                                 Clean.html_id(val.to_s)

                               when attr == :class
                                 val.map { |name|
                                   Clean.css_class_name(name)
                                 }.join(" ".freeze)

                               when target[:tag_name] == :style && attr == :type
                                 'text/css'

                               when ::WWW_App::HTML::TAGS_TO_ATTRIBUTES[target[:tag_name]].include?(attr)
                                 Clean.html(val)

                               else
                                 fail "Invalid attr: #{attr.inspect}"

                               end # case attr

          } # === each attr

          stacks[:attributes] = attributes.inject([]) { |memo, (k,v)|
            memo << "#{k}=\"#{v}\""
            memo
          }.join " ".freeze

        when t_name == :doc_type
          if tag[:text] == "<!DOCTYPE html>"
            final << tag[:text]
            final << NEW_LINE
          else
            fail "Unknown doc type: #{tag[:text].inspect}"
          end

        when t_name == :text
          final.<<(
            tag[:skip_escape] ?
            tag[:value] :
            Clean.html(tag[:value])
          )


        when t_name == :meta
          case
          when tag[:http_equiv]
            key_name    = "http-equiv"
            key_content = tag[:http_equiv].gsub(/[^a-zA-Z\/\;\ 0-9\=\-]+/, '')
            content     = tag[:content].gsub(/[^a-zA-Z\/\;\ 0-9\=\-]+/, '')
          else
            fail ArgumentError, tag.keys.inspect
          end

          final << (
            %^#{SPACES(indent)}<meta #{key_name}="#{key_content}" content="#{content}" />^
          )

        when t_name == :html       # === :html tag ================
          todo = [
            :clean_attrs, {:lang=>(tag[:lang] || 'en')}, tag,
            :open, :html
          ].concat(tag[:children]).concat([:new_line, :close, :html]).concat(todo)

        when t_name == :head       # === :head tag =================
          todo = [ :open, :head, :new_line ].
            concat(tag[:children] || []).
            concat([:new_line, :close, :head]).
            concat(todo)

        when t_name == :title && !parent(tag)
          nil # do nothing

        when t_name == :_  # =============== :_ tag ========
          nil # do nothing

        when t_name && ::WWW_App::HTML::TAGS.include?(t_name) # === HTML tags =====
          attrs = {}
          attrs.default KEY_REQUIRED

          new_todo = []
          t2a = ::WWW_App::HTML::TAGS_TO_ATTRIBUTES

          tag.each { |attr_name, v|
            if t2a[:all].include?(attr_name) || (t2a[tag[:tag_name]] && t2a[tag[:tag_name]].include?(attr_name))
              attrs[attr_name] = v
            end
          }

          if !attrs.empty?
            new_todo.concat [:clean_attrs, attrs, tag]
          end

          new_todo.concat [:open, tag[:tag_name]]

          if tag[:children]
            new_todo.concat tag[:children]
            if tag[:children].last[:tag_name] != :text
              new_todo << :new_line
            end
          end
          new_todo.concat [:close, tag[:tag_name]]
          todo = new_todo.concat(todo)

        when tag == :javascript
          vals = todo.shift
          clean_vals = vals.map { |raw_x|
            x = case raw_x
                when ::Symbol, ::String
                  Clean.html(raw_x.to_s)
                when ::Array
                  to_clean_text :javascript, raw_x
                when ::Numeric
                  x
                else
                  fail "Unknown type for json: #{raw_x.inspect}"
                end
          }

        when tag == :to_json
          vals = todo.shift
          ::Escape_Escape_Escape.json_encode(to_clean_text(:javascript, vals))


        when t_name == :style
          next

        when t_name == :style_tags # =============== <style ..> TAG =================
          next if tag[:children].empty?

          new_todo = [
            :clean_attrs, {:type=>'text/css'}, {:tag_name=>:style},
            :open, :style
          ]

          indent += 2
          css_final      = ""
          flatten_groups = []
          groups         = tag[:children].dup

          # === flatten groups
          #  style
          #    div, span {
          #      a:link, a:visited {
          #  --->
          #  style
          #    div a:link, div a:visited, span a:link, span a:visited  {
          #
          prev = nil
          while (style = groups.shift)
            case
            when style[:tag_name] == :style
              groups = style[:children].dup.concat(groups)

            when style[:tag_name] == :group
              groups = style[:children].dup.concat(groups)
              prev = nil
              flatten_groups << style

            when parent?(style, :group)
              if style[:__]
                style[:__children] = []
              end

              if prev && prev[:__]
                prev[:__children] << style
                style[:__parent] = prev
              end

              prev = style

            else # === it's an HTML element w/:css
              flatten_groups << style
            end
          end # === while style

          flatten_groups.each { |style|
            css_final << "\n" << SPACES(indent) << css_selector(style, :full) << " {\n".freeze

            the_css = style[:css] || (parent?(style, :group) && style[:parent][:css])
            if the_css
              indent += 2
              the_css.each { |raw_k, raw_val|
                name = begin
                          clean_k = ::WWW_App::Clean.css_attr(raw_k.to_s.gsub('_','-'))
                          fail("Invalid name for css property name: #{raw_k.inspect}") if !clean_k || clean_k.empty?
                          clean_k
                        end

                raw_val  = raw_val.is_a?(Array) ? raw_val.join(COMMA) : raw_val.to_s

                v = case

                    when name[IMAGE_AT_END]
                      case raw_val
                      when 'inherit', 'none'
                        raw_val
                      else
                        "url(#{Clean.href(raw_val)})"
                      end

                    when ::WWW_App::CSS::PROPERTIES.include?(raw_k)
                      Clean.css_value raw_val

                    else
                      fail "Invalid css attr: #{name.inspect}"

                    end # === case

                css_final << SPACES(indent) << "#{name}: #{v};\n"
              } # === each style
              indent -= 2
            end # === if style[:css]

            css_final << SPACES(indent) << "}\n".freeze << SPACES(indent - 2)
          }

          indent -= 2
          new_todo.concat [{:tag_name=>:text, :skip_escape=>true, :value=>css_final}, :close, :style]
          todo = new_todo.concat(todo)


        when tag == :style # ============

          h = vals

          if h[:tag] == :script && h[:content] && !h[:content].empty?
            return <<-EOF
              <script type="text/css">
                WWW_App.compile(
                  #{to_clean_text :to_json, h[:content]}
                );
              </script>
            EOF
          end

          html = h[:childs].map { |tag_index|
            to_clean_text(:html, @tag_arr[tag_index])
          }.join(NEW_LINE).strip

          return unless  h[:render?]

          if html.empty? && h[:text]
            html = if h[:text].is_a?(::Symbol)
                     h[:text].to_mustache(:html)
                   else
                     if h[:text].is_a?(::Hash)
                       if h[:text][:escape] == false
                         h[:text][:value]
                       else
                         Clean.html(h[:text][:value].strip)
                       end
                     else
                       Clean.html(h[:text].strip)
                     end
                   end
          end # === if html.empty?

          (html = nil) if html.empty?

          case
          when h[:tag] == :render_if
            key   = h[:attrs][:key]
            open  = "{{# coll.#{key} }}"
            close = "{{/ coll.#{key} }}"

          when h[:tag] == :render_unless
            key   = h[:attrs][:key]
            open  = "{{^ coll.#{key} }}"
            close = "{{/ coll.#{key} }}"

          when Methods[:elements].include?(h[:tag])
            open  = "<#{h[:tag]}#{to_clean_text(:attrs, h)}"
            if NO_END_TAGS.include?(h[:tag])
              open += ' />'
              close = nil
            else
              open += '>'
              close = "</#{h[:tag]}>"
            end

          else
            fail "Unknown html tag: #{h[:tag].inspect}"

          end # === case h[:tag]

          if h[:tag]
            [open, html, close].compact.join
          else
            html
          end # === if

        else
          fail "Unknown: #{tag.inspect[0,30]}"
        end # === case
      end # === while

      final

      @mustache ||= begin
                      final = if false
                                (page_title { 'Unknown Page Title' }) unless @page_title

                                Document_Template.gsub(/:(HEAD|BODY)/) { |match|
                                  case name
                                  when ':HEAD'
                                    to_clean_text(:html, @head[:childs])
                                  when ':BODY'
                                    to_clean_text(:html, @body)
                                  else
                                    match
                                  end
                                }
                              else
                                # to_clean_text(:html, final)
                                final
                              end

                      mustache = ::Mustache.new
                      mustache.template = Clean.clean_utf8(final)
                      mustache
                    end

      to_html(*args)
    end # === to_html

    module OLD
  #
  # Examples
  #    dom_id             -> the current dom id of the current element
  #    dom_id :default    -> if no dom it, set/get default of current element
  #    dom_id {:element:} -> dom id of element: {:type=>:html, :tag=>...}
  #
  def dom_id *args

    use_default = false

    case
    when args.empty?
      e = tag!
      # do nothing else

    when args.size == 1 && args.first == :default
      e = tag!
      use_default = true

    when args.size == 1 && args.first.is_a?(::Hash) && args.first[:type]==:html
      e = args.first

    else
      fail "Unknown args: #{args.inspect}"
    end

    id = e[:attrs][:id]
    return id if id
    return nil unless use_default

    e[:default_id] ||= begin
                           key = e[:tag]
                           @default_ids[key] ||= -1
                           @default_ids[key] += 1
                         end
  end # === def dom_id

  #
  # Examples
  #    selector_id   -> a series of ids and tags to be used as a JS selector
  #                     Example:
  #                        #id tag tag
  #                        tag tag
  #
  #
  def selector_id
    i        = tag![:tag_index]
    id_given = false
    classes  = []

    while !id_given && i && i > -1
      e         = @tag_arr[i]
      id        = dom_id e
      (id_given = true) if id

      if e[:tag] == :body && !classes.empty?
        # do nothing because
        # we do not want 'body tag.class tag.class'
      else
        case
        when id
          classes << "##{id}"
        else
          classes << e[:tag]
        end # === case
      end # === if

      i = e[:parent_index]
    end

    return 'body' if classes.empty?
    classes.join SPACE
  end

  #
  # Examples
  #    css_id             -> current css id of element.
  #                          It uses the first class, if any, found.
  #                          #id.class     -> if #id and first class found.
  #                          #id           -> if class is missing and id given.
  #                          #id tag.class -> if class given and ancestor has id.
  #                          #id tag tag   -> if no class given and ancestor has id.
  #                          tag tag tag   -> if no ancestor has class.
  #
  #    css_id :my_class   -> same as 'css_id()' except
  #                          'my_class' overrides :class attribute of current
  #                          element.
  #
  #
  def css_id *args

    str_class = nil

    case args.size
    when 0
      fail "Not in a tag." unless tag!
      str_class = @css_id_override
    when 1
      str_class = args.first
    else
      fail "Unknown args: #{args.inspect}"
    end

    i        = tag![:tag_index]
    id_given = false
    classes  = []

    while !id_given && i && i > -1
      e           = @tag_arr[i]
      id          = dom_id e
      first_class = e[:attrs][:class].first

      if id
        id_given = true
        if str_class
          classes.unshift(
            str_class.is_a?(::Symbol) ?
            "##{id}.#{str_class}" :
            "##{id}#{str_class}"
          )
        else
          classes.unshift "##{id}"
        end

      else # no id given
        if str_class
          classes.unshift(
            str_class.is_a?(::Symbol) ?
            "#{e[:tag]}.#{str_class}" :
            "#{e[:tag]}#{str_class}"
          )
        elsif first_class
          classes.unshift "#{e[:tag]}.#{first_class}"
        else
          if e[:tag] != :body || (classes.empty?)
            classes.unshift "#{e[:tag]}"
          end
        end # if first_class

      end # if id

      i = e[:parent_index]
      break if i == @body[:tag_index] && !classes.empty?
    end

    classes.join SPACE
  end

    end # === module OLD
  end # === module TO
end # === class WWW_App



__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    :HEAD
  </head>
  :BODY
</html>
