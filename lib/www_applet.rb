
require 'sanitize'

class WWW_Applet

  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  INVALID_CSS_CLASS_CHARS     = /[^a-z0-9\#\:\_\-\ ]/i
  INVALID_CSS_PROP_NAME_CHARS = /[^a-z0-9\-\_]/i

  Document_Template  = File.read(__FILE__).split("__END__").last.strip
  Sanitize_Config    = {

    :allow_doctype   => true,
    :allow_comments  => false,
    :remove_contents => true,

    :elements => %w[

      html  head  title  meta  style  link 
      body  div

      b      em     i  strong  u  a 
      abbr   blockquote 
      br     cite   code 
      ul     ol     li  p  pre  q 
      sup    sub 
      form   input  button

    ],

    :attributes => {
      :all         => ['id', 'class'],
      'a'          => ['href'],
      'blockquote' => ['cite'],
      'form'       => ['action', 'method', 'accept-charset'],
      'input'      => ['type', 'name', 'value'],
      'style'      => ['type'],
      'script'     => ['type', 'src', 'language'],
      'link'       => ['rel', 'type', 'sizes', 'href', 'title'],
      'meta'       => ['name', 'http-equiv', 'property', 'content', 'charset'],
      'html'       => ['lang']
    },

    :protocols=> {
      'a'          => {'href'=>['ftp', 'http', 'https', :relative]},
      'blockquote' => {'cite'=>[:relative]},
      'form'       => {'action'=>[:relative]},
      'script'     => {'src'=>[:relative]},
      'link'       => {'href'=>[:relative]}
    },

    :css => {
      :allow_comments => false,
      :allow_hacks    => false,
      :at_rules       => [ 'font-face', 'media' ],
      :protocols      => [ :relative ],
      :properties     => Sanitize::Config::RELAXED[:css][:properties]
    }

  }

  class << self # ===================================================

    def new
      fail "Not implemented."
    end

    def new_class file_name = nil, &blok
      Class.new(BasicObject) {
        include ::WWW_Applet::Mod

        if file_name
          eval(<<-EOF.strip, nil, file_name, 1-1)
            def run
              #{::File.read(file_name)}
            end
          EOF
        else

          define_method :run do
            instance_eval &blok
          end

        end
      }
    end # === def new_class

  end # === class self ==============================================

  module Mod # ======================================================

    private

    BANG     = '!'
    NEW_LINE = "\n"
    SPACE    = ' '

    def initialize data = nil
      @title       = nil
      @curr_id     = -1
      @style       = {}
      @scripts     = []
      @body        = []
      @data        = data || {}
      @html_page   = nil
      @cache       = {}
      @has_meta    = false
      @has_script  = false
      @has_title   = false
      @default_ids = {}

      @head      = new_html(:head)
      @body      = new_html(:body)
      @parent    = @body
      @creating_html = nil
    end

    def is_doc?
      @is_doc || !@style.empty? || @has_title
    end

    def fail *args
      ::Object.new.send :fail, *args
    end

    def creating_html?
      !!@creating_html
    end

    def pop
      e = @creating_html
      @creating_html = nil
      e
    end

    def dom_id e
      id = e[:attrs] && e[:attrs][:id]
      return id if id

      e[:default_id] ||= begin
                           tag = e[:tag]
                           @default_ids[tag] ||= -1
                           @default_ids[tag] += 1
                           "#{tag}_#{@default_ids[tag]}"
                         end
    end

    def curr_id
      dom_id(@parent)
    end

    def curr_css_id
      if @parent[:tag] == :body
        return '#body'
      end

      '#' << curr_id
    end

    def parent? tag
      @parent && @parent[:tag] == tag
    end

    def parent c
      origin = @parent
      @parent = c
      result = yield
      @parent = origin
      result
    end

    def capture &blok
      h = {:childs=>[]}
      parent(h, &blok)
      h[:childs]
    end

    def style h
      @style = h
    end

    def scripts
      @scripts
    end

    def new_html *args, &blok
      new_child :html, *args, &blok
    end

    def new_style *args, &blok
      new_html :style, *args, &blok
    end

    def new_child type, tag, attrs=nil, &blok
      e = {
        type:   type,
        tag:    tag,
        attrs:  attrs,
        text:   nil,
        childs: []
      }

      update_html e, attrs, &blok

      e
    end

    def add_id html, id
      attrs = (html[:attrs] ||= {})
      old_id = attrs && attrs[:id]
      fail("Id already set: #{old_id} new: #{id}") if old_id
      attrs[:id] = id
      html
    end

    def add_classes html, *names
      html[:attrs] ||= {}

      old_class = html[:attrs][:class]
      new_class = names.compact.join(SPACE)

      return html if old_class == new_class
      html[:attrs][:class] = [old_class, new_class].compact.join(SPACE)
      html
    end

    def update_html e, attrs=nil, &blok
      if attrs
        e[:attrs] ||= {}
        add_id(e, attrs[:id]) if attrs[:id]
        e[:attrs].merge! attrs
      end

      if blok
        result = parent(e) {
          blok.call
        }

        e[:text] = result if self != result && result.is_a?(String)
      end

      e
    end

    def title string
      @title = string
    end

    def no_title
      title { 'No title' }
    end

    def title &blok
      @has_title = true

      c = new_html(:title, &blok)
      if parent?(:body)
        @head[:childs].push c
      else
        @parent[:childs].push c
      end
      c
    end

    def meta *args
      @has_meta = true

      fail "Not allowed outside of :head" unless parent?(:body)
      c = new_html(:meta, *args)
      @head[:childs].push c
      c
    end

    def script *args, &blok
      @has_script = true

      fail "Not allowed outside of :head" unless parent?(:body)
      c = new_html(:script, *args, &blok)
      @head[:childs].push c
      c
    end

    def array_to_text a
      hash_to_text(:type=>:html, :childs=>a)
    end

    def hash_to_text h
      case h[:type]
      when :attrs
        final = h[:value].map { |k,raw_v|
          v = raw_v.is_a?(Array) ? raw_v.join(SPACE) : raw_v
          %^#{k.to_s.gsub(INVALID_ATTR_CHARS,'_')}="#{Escape_Escape_Escape.inner_html(v)}"^
        }.join SPACE

        if final.empty?
          ''
        else
          " " << final
        end

      when :styles
        h[:value].map { |k,styles|
          %^#{k.to_s.gsub(INVALID_CSS_CLASS_CHARS, '_')} {
              #{hash_to_text :type=>:style, :value=>styles}
            }
          ^
        }.join.strip

      when :style
        h[:value].map { |k,v|
          %^#{k.to_s.gsub(INVALID_CSS_PROP_NAME_CHARS, '_')}: #{v};^
        }.join("\n").strip

      when :html
        if h[:tag] == :style
          return hash_to_text(type: :styles, value: h[:attrs])
        end

        html = h[:childs].map { |c|
          "#{hash_to_text c}"
        }.join NEW_LINE

        if h[:text] && !(h[:text].strip).empty?
          if html.empty?
            html = h[:text]
          else
            html << hash_to_text(new_html(:div, :class=>'text') { h[:text] })
          end
        end

        if h[:tag]
          %^
            <#{h[:tag]}#{h[:attrs] && hash_to_text(:type=>:attrs, :value=>h[:attrs])}>#{html}</#{h[:tag]}>
          ^.strip
        else
          html
        end

      when :script
        fail "Not ready yet."

      else
        fail "Unknown type: #{h[:text].inspect}"
      end
    end

    def in_html?
      creating_html? && @creating_html[:type] == :html
    end

    def method_missing name, *args, &blok

      str_name = name.to_s

      case

      when creating_html?

        case
        when in_html?

          str_name = name.to_s
          if str_name[BANG] # === id
            add_id @creating_html, str_name.sub(BANG, '')
          else # === css class name
            add_classes @creating_html, name, (args.first && args.first.delete(:class))
          end

          if !args.empty? || blok
            @parent[:childs] << update_html(pop, *args, &blok)
          else
            self
          end
        else
          super
        end

      else # not creating_html?

          case

          when args.size == 1 && !blok && ::Sanitize::Config::RELAXED[:css][:properties].include?(css_name = str_name.gsub('_', '-'))
            # set style
            @style[curr_css_id] ||= {}
            @style[curr_css_id][css_name] = args.first

          when ::Sanitize::Config::RELAXED[:elements].include?(str_name)
            # === start of creating html:
            case
            when args.empty? && !blok
              @creating_html = new_html(name)
            else
              e = new_html(name, *args, &blok)
              @parent[:childs] << e
            end

          else
            super

          end

      end

      self
    end # === def method_missing

    public def to_html

      return @html_page if @html_page

      run

      final = if is_doc?
                # Remember: to use !BODY first, because
                # :head content might include a '!HEAD'
                # value.
                no_title unless @has_title
                if !@style.empty?
                  @head[:childs] << new_html(:style, @style)
                end
                Document_Template.
                  sub('!BODY', hash_to_text(@body)).
                  sub('!HEAD', array_to_text(@head[:childs]))
              else
                array_to_text(@body[:childs])
              end

      utf_8 = Escape_Escape_Escape.clean_utf8(final)

      @html_page = if is_doc?
                     Sanitize.document( utf_8 , WWW_Applet::Sanitize_Config)
                   else
                     Sanitize.fragment( utf_8 , WWW_Applet::Sanitize_Config)
                   end
    end # === def to_html

  end # === module Mod ==============================================

end # === class WWW_Applet ==========================================

__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    !HEAD
  </head>
  !BODY
</html>
