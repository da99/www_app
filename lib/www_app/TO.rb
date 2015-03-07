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
    alias_method :[], :fetch

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

    def to_html *args
      return @mustache.render(*args) if @mustache

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

          # ===  v1.3 ===========================
        when type == :javascript && vals.is_a?(::Array)
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

        when type == :to_json && vals.is_a?(::Array)
          ::Escape_Escape_Escape.json_encode(to_clean_text(:javascript, vals))

        when type == :style_classes && vals.is_a?(::Hash)
          h = vals
          h.map { |raw_k,styles|
            k = raw_k.to_s

            <<-EOF
            #{Clean.css_selector k} {
            #{to_clean_text :styles, styles}
          }
            EOF
          }.join.strip

        when type == :styles && vals.is_a?(::Hash)
          h = vals
          h.map { |k,raw_v|
            name  = begin
                      clean_k = ::WWW_App::Clean.css_attr(k.to_s.gsub('_','-'))
                      fail("Invalid name for css property name: #{k.inspect}") if !clean_k || clean_k.empty?
                      clean_k
                    end

            raw_v = raw_v.to_s

            v = case

                when name[IMAGE_AT_END]
                  case raw_v
                  when 'inherit', 'none'
                    raw_v
                  else
                    "url(#{Clean.href(raw_v)})"
                  end

                when Methods[:css][:properties].include?(k)
                  Clean.css_value raw_v

                else
                  fail "Invalid css attr: #{name.inspect}"

                end # === case

            %^#{name}: #{v};^
          }.join("\n").strip

        when type == :attrs && vals.is_a?(::Hash)
          h     = vals[:attrs]
          tag   = vals
          final = h.map { |k,raw_v|

            fail "Unknown attr: #{k.inspect}" if !ALLOWED_ATTRS.include?(k)

            next if raw_v.is_a?(::Array) && raw_v.empty?

            v = raw_v

            attr_name = k.to_s.gsub(::WWW_App::INVALID_ATTR_CHARS, '_')
            fail("Invalid name for html attr: #{k.inspect}") if !attr_name || attr_name.empty?

            attr_val = case
                       when k == :href && tag[:tag] == :a
                         Clean.mustache :href, v

                       when k == :action || k == :src || k == :href
                         Clean.relative_href(v)

                       when k == :class
                         v.map { |n|
                           Clean.css_class_name(n)
                         }.join SPACE

                       when k == :id
                         Clean.html_id v.to_s

                       when ALLOWED_ATTRS[k]
                         Clean.html(v)

                       else
                         fail "Invalid attr: #{k.inspect}"

                       end # === case

            %*#{attr_name}="#{attr_val}"*

          }.compact.join SPACE

          final.empty? ?
            '' :
            (" " << final)

        when type == :html && vals.is_a?(::Array)
          a = vals
          a.map { |tag_index|
            to_clean_text(:html, @tag_arr[tag_index])
          }.join NEW_LINE

        when type == :html && vals.is_a?(::Hash)

          h = vals

          fail("Unknown type: #{h.inspect}") if h[:type] != :html

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
          end

        else
          fail "Unknown: #{tag.inspect}"
        end # === case
      end # === while

      final

      @mustache ||= begin
                      final = if is_doc?
                                # Remember: to use !BODY first, because
                                # :head content might include a '!HEAD'
                                # value.
                                (page_title { 'Unknown Page Title' }) unless @page_title

                                Document_Template.
                                  sub('!BODY', to_clean_text(:html, @body)).
                                  sub('!HEAD', to_clean_text(:html, @head[:childs]))
                              else
                                to_clean_text(:html, @body[:childs])
                              end

                      mustache = ::Mustache.new
                      mustache.template = Clean.clean_utf8(final)
                      mustache
                    end

      to_html(*args)
    end # === to_html

  end # === module TO

end # === class WWW_App



__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    !HEAD
  </head>
  !BODY
</html>
