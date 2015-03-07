

class WWW_App < BasicObject
end # === class WWW_App

require 'www_app/CSS'
require 'www_app/HTML'
require 'www_app/JavaScript'
require 'www_app/TO'

# ===================================================================
# === WWW_App ====================================================
# ===================================================================
class WWW_App
# ===================================================================

  include ::Kernel

  Unescaped         = ::Class.new(::StandardError)
  Not_Unique        = ::Class.new(::StandardError)
  Wrong_Parent      = ::Class.new(::StandardError)
  Invalid_Type      = ::Class.new(::StandardError)
  HTML_ID_Duplicate = ::Class.new(Not_Unique)

  ALWAYS_END_TAGS = [:script]

  INVALID_ATTR_CHARS          = /[^a-z0-9\_\-]/i
  IMAGE_AT_END                = /image\z/i

  NEW_LINE   = "\n".freeze
  HASH       = '#'.freeze
  DOT        = '.'.freeze
  BANG       = '!'.freeze
  NEW_LINE   = "\n".freeze
  SPACE      = ' '.freeze
  BLANK      = ''.freeze
  BODY       = 'body'.freeze
  UNDERSCORE = '_'.freeze


  #
  # NOTE: Properties are defined first,
  # so :elements methods can over-write them,
  # just in case there are duplicates.
  #
  include WWW_App::CSS
  include WWW_App::HTML
  include WWW_App::TO
  include WWW_App::JavaScript

  attr_reader :tag, :tags
  def initialize
    @mustache          = nil
    @html_ids          = {}

    @tags = []
    @tag  = nil

    create(:body) do
      yield
    end

    freeze
  end
  private :style

  private # ===============================================

  # =================================================================
  #                 Miscellaneaous Helpers
  # =================================================================

  def SPACE indent
    ' '.freeze * indent
  end

  def tag? name
    tag && tag[:type] == name
  end

  def tag_or_ancestor? name
    !!find_nearest(name)
  end

  def find_nearest name
    return @tag if tag?(name)
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
    return self if tag?(name)
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

  def first_class
    tag[:class] && tag[:class].first
  end

  def dom_id?
    tag && !!tag[:id]
  end

  def parent?
    !!parent
  end

  def parent
    tag && tag[:parent]
  end

  def create name, opts = nil
    old = @tag
    new = {:type=>name}

    # === If:
    #   we are creating an HTML element
    #   within a group, then we either start
    #   a new group or stay here.
    if HTML_TAGS.include?(name) && tag_or_ancestor?(:groups)
      if tag?(:groups)
        create :group
      else
        # Example: div.id(:main)._.div.^(:my_class)
        stay_or_go_up_to_if_exists(:group) if tag && !tag[:_]
      end
    end

    # === Add to parent's children array:
    if old
      old[:children] ||= []
      old[:children] << new
      new[:parent] = old
    else # === Example: :head, :body, etc.
      @tags << new
    end

    @tag = new

    @tag.merge!(opts) if opts

    if block_given?
      close { yield }
    end

    self
  end # === def create

  def close
    group = find_nearest(:group)
    if group
      stay_or_go_up_to :group
      final_parent = parent

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
    final_parent = parent
    yield if block_given?
    @tag = final_parent

    self
  end # === close

  # =====================================================
  # ==== FROM: v.1.x ====================================
  # =====================================================

  private # =========================================================

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

  # =================================================================
  #                    Parent-related methods
  # =================================================================

  def css_parent?
    !@css_arr.empty?
  end

  def parent? *args
    return(tag! && !tag![:parent_index].nil?) if args.empty?
    fail("Unknown args: #{args.first}") if args.size > 1
    return false unless parent

    sym_tag = args.first

    case sym_tag
    when :html, :css, :script
      parent[:type] == sym_tag
    else
      parent[:tag] == sym_tag
    end
  end

  def parent
    fail "Not in a tag." unless tag!
    fail "No parent: #{tag![:tag].inspect}, #{tag![:tag_index]}" if !tag![:parent_index]
    @tag_arr[tag![:parent_index]]
  end

  # =================================================================
  #                    Tag (aka element)-related methods
  # =================================================================


  def in_tag t
    orig = @current_tag_index
    @current_tag_index = t[:tag_index]
    yield
    @current_tag_index = orig
    nil
  end

  public def /
    fail "No block allowed here: :/" if block_given?
    close_tag
  end

  def close_tag
    orig_tag = tag!
    is_script = tag?(:script)

    if block_given?

      results = yield

      results = nil if is_script

      # The :yield may have left some opened tags, :input, :br/
      # So we make sure we are in the original tag/element
      # when we want to make some final changes.
      in_tag(orig_tag) {
        if tag?(:form)
          input(:hidden, :auth_token, :auth_token.to_mustache(:html))
        end

        if (results.is_a?(::Hash) && results[:type] && !results[:tag] && results[:type] != :string)
          fail Invalid_Type, results[:type].inspect
        end

        if (results.is_a?(::Hash) && results[:type] == :string) || results.is_a?(::String) || results.is_a?(::Symbol)
          tag![:text] = results
        end
      }
    end

    orig_tag[:is_closed] = true
    @current_tag_index = orig_tag[:parent_index]

    nil
  end

  def alter_css_property name, *args
    @tag[:css] ||= {}
    @tag[:css][name] = args
    self
  end

  def input *args
    case
    when args.size === 3
      tag(:input).type(args[0]).name(args[1]).value(args[2])
    else
      super
    end
  end

end # === class WWW_App ==========================================

