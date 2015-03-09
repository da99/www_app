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

  Document_Template  = ::File.read(__FILE__).split("__END__").last.strip

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

    KEY_REQUIRED = proc { |hash, k|
      fail "Key not set: #{k.inspect}"
    }

    def to_raw_text
      str    = ""
      indent = 0
      print_tag = lambda { |t|
        info      = t.reject { |n| [:tag_name, :parent, :children].include?( n ) }

        str += "#{" " * indent}#{t[:tag_name].inspect} -- #{info.inspect}\n"
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
      return @mustache.render(*args) if @mustache

      final  = ""
      indent = 0
      todo   = @tags.dup
      last   = nil
      stacks = {}

      while !todo.empty?
        tag = todo.shift

        case

        when tag == :new_line
          final << NEW_LINE

        when tag == :open
          attributes = stacks.delete :attributes

          unless indent.zero?
            final << NEW_LINE << SPACE(indent)
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
            final << SPACE(indent)
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

        when tag.is_a?(Hash) && tag[:tag_name] == :text
          final.<<(
            tag[:skip_escape] ?
            tag[:value] :
            Clean.html(tag[:value])
          )

        when tag.is_a?(Hash) && ::WWW_App::HTML::TAGS.include?(tag[:tag_name])
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

        when tag == :style_classes
          h = todo.shift
          h.map { |raw_k,styles|
            k = raw_k.to_s
            <<-EOF
              #{Clean.css_selector k} {
                #{to_clean_text :styles, styles}
              }
            EOF
          }.join.strip

        when tag.is_a?(Hash) && tag[:tag_name] == :style # =============== <style ..> TAG =================
          new_todo = [
            :clean_attrs, {:type=>'text/css'}, tag,
            :open, tag[:tag_name]
          ]

          indent += 2
          css_final = ""
          tag[:children].each { |group|
            names = group[:children].inject([]) { |memo, child|
              name = child[:tag_name].to_s
              if child[:id]
                name << '#'.freeze << Clean.html_id(child[:id]).to_s
              end

              if child[:class]
                name.<< '.'.freeze << (child[:class].map { |name| Clean.css_class_name(name) }.join('.'.freeze))
              end

              if child[:pseudo]
                name << ":#{child[:pseudo]}"
              end

              memo << name
            }.join(', '.freeze)

            css_final << "\n" << SPACE(indent) << names << " {\n".freeze

            if group[:css]
              indent += 2
              group[:css].each { |raw_k, raw_val|
                name = begin
                          clean_k = ::WWW_App::Clean.css_attr(raw_k.to_s.gsub('_','-'))
                          fail("Invalid name for css property name: #{raw_k.inspect}") if !clean_k || clean_k.empty?
                          clean_k
                        end
                raw_val  = raw_val.is_a?(Array) ? raw_val.join(', ') : raw_val.to_s
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

                css_final << SPACE(indent) << "#{name}: #{v};\n"
              } # === each group
              indent -= 2
            end # === if group[:css]

            css_final << SPACE(indent) << "}\n".freeze << SPACE(indent - 2)
          }

          indent -= 2
          new_todo.concat [{:tag_name=>:text, :skip_escape=>true, :value=>css_final}, :close, tag[:tag_name]]
          todo = new_todo.concat(todo)


        when tag == :style

          h = vals

          fail("Unknown type: #{h.inspect}") if h[:tag_name] != :html

          if h[:tag] == :style
            return <<-EOF
              <style type="text/css">
                #{to_clean_text :style_classes, h[:css]}
              </style>
            EOF
          end

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
