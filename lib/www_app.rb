

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
  SPACE      = ' '.freeze
  BLANK      = ''.freeze
  BODY       = 'body'.freeze
  UNDERSCORE = '_'.freeze


  #
  # NOTE: CSS Properties are defined first,
  # so HTML elements methods can over-write them,
  # just in case there are duplicates.
  #
  include CSS
  include HTML
  include JavaScript
  include TO

  private # ===============================================

  def initialize &blok
    @html_ids = {}
    @tags     = []
    @tag      = nil

    instance_eval &blok
  end

  def SPACES indent
    SPACE * indent
  end

  def args_to_traversal_args *args
    tags = nil
    tag  = nil
    syms = []

    args.each { |a|
      case a
      when ::Symbol
        syms << a
      when ::Array
        tags = a
      when ::Hash
        tag  = a
        tags = [a]
      else
        fail ::ArgumentError, "#{args.inspect}"
      end
    }

    tags ||= @tags.dup
    tag  ||= @tag
    return [tags, tag, syms]
  end

  def de_ref tag, sym = nil
    t = tag 
    while t && [:_, :style, :group].freeze.include?(t[:tag_name])
      t = t[:parent]
    end
    t

    case sym
    when :tag_name, :id
      t && t[sym]
    when nil
      t
    else
      fail ::ArgumentError, "Unknown args: #{sym.inspect}"
    end
  end

  # Ex:
  #
  #   find_all :body, :style, :span
  #   find_all [], :body, :a
  #   find_all {tag}, :body, :a
  #
  def find_all *raw_args
    tags, tag, syms = args_to_traversal_args(*raw_args)

    fail ::ArgumentError, "tag names to find empty: #{syms.inspect}" if syms.empty?

    found = []
    while !tags.empty?
      t = tags.shift
      if t[:children]
        tags = t[:children].dup.concat tags
      end

      (found << t) if syms.include?(t[:tag_name])
    end

    found
  end

  #
  # Ex:
  #
  #   detect :body, :style, :span
  #   detect [], :body, :a
  #   detect {tag}, :body, :a
  #
  def detect *raw_args
    tags, tag, syms = args_to_traversal_args(*raw_args)

    found = nil
    while !found && !tags.empty?
      found = tags.shift
      if !syms.include?(found[:tag_name])
        if found[:children]
          tags = found[:children].dup.concat tags
        end
        found = nil
      end
    end

    found
  end

  def tag? *args
    case args.size
    when 1
      tag = @tag
      name = args.first
    when 2
      tag = args.first
      name = args.last
    else
      fail "Unknown args: #{args.inspect}"
    end

    tag && (tag[:tag_name] == name || !!tag[name])
  end

  def tag_or_ancestor? *args
    !!find_nearest(*args)
  end

  def ancestor? *args
    !!(find_ancestor *args)
  end

  def find_nearest *raw_args
    tags, tag, syms = args_to_traversal_args(*raw_args)
    return tag if tag?(tag, syms.first)
    find_ancestor *raw_args
  end

  def find_ancestor *raw_args
    tags, tag, syms = args_to_traversal_args(*raw_args)
    name = syms.first

    return nil unless tag
    ancestor = tag[:parent]
    while ancestor && !tag?(ancestor, name)
      ancestor = ancestor[:parent]
    end 

    return ancestor if tag?(ancestor, name)
  end

  def go_up_to_if_exists name
    target = find_ancestor name
    (@tag = target) if target
    self
  end

  def go_up_to name
    go_up_to_if_exists name
    fail "No parent found: #{name.inspect}" unless tag?(name)
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
    fail "No parent found: #{name.inspect}" unless tag?(name)
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

  #
  # Ex:
  #
  #   parent?
  #   parent? :body
  #   parent? tag, :div
  #
  def parent? *args
    case
    when args.length == 0
      tag = @tag[:parent]
      name = nil

    when args.length == 1 && args.first.is_a?(::Symbol)
      tag  = @tag
      name = args.first

    when args.length == 2
      tag = args.first
      name = args.last

    else
      fail ::ArgumentError, "Unknown args: #{args.inspect}"
    end # === case

    p = parent(tag)
    return true if p && !name
    return true if p && p[:tag_name] == name
    return true if !p && name == :body
    false
  end # === def parent?

  #
  # Ex:
  #
  #   parent
  #   parent tag
  #
  def parent *args
    case
    when args.length == 0
      tag = @tag

    when args.length == 1 && args.first.is_a?(::Hash)
      tag  = args.first
    else
      fail ::ArgumentError, "Unknown args: #{args.inspect}"
    end # === case

    tag && tag[:parent]
  end

  def in_tag t
    if t.is_a?(::Symbol)
      in_tag(detect(t)) {
        yield
      }
      return self

    else # =============================
      orig = @tag
      @tag = t
      yield
      @tag = orig
      nil

    end # === if t == :head
  end

  def create name, opts = nil
    #
    # Ex:
    #   _.id(:the_body).^(:loading)
    #   div {
    #   }
    #
    if @tag && @tag[:tag_name] == :_
      go_up if !@tag[:closed]

      #
      # Ex:
      #   _.^(:happy) {
      #     a { }
      #   }
      #
      fail "New tags not allowed here." if (@tag && @tag[:closed]) && !ancestor?(:group)
    end

    # === If:
    #   we are creating an HTML element
    #   within a group, then we either start
    #   a new group or stay here.
    if HTML::TAGS.include?(name) && tag_or_ancestor?(:groups)
      if tag?(:groups)
        create :group
      else
        # Example: div.id(:main)._.div.^(:my_class)
        stay_or_go_up_to_if_exists(:group) if @tag && !@tag[:_]
      end
    end

    old = @tag
    new = {:tag_name=>name}

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

    orig = @tag

    if block_given?
      results = yield

      results = nil if tag?(:script)

      # The :yield may have left some opened tags, :input, :br/
      # So we make sure we are in the original tag/element
      # when we want to make some final changes.
      in_tag(orig) {
        if tag?(:form)
          input(:hidden, :auth_token, :auth_token.to_mustache(:html))
        end

        if (results.is_a?(::Hash) && results[:tag_name] && !results[:tag] && results[:tag_name] != :string)
          fail ::Invalid_Type, results[:tag_name].inspect
        end

        if (results.is_a?(::Hash) && results[:tag_name] == :string) || results.is_a?(::String) || results.is_a?(::Symbol)
          @tag[:children] ||= []
          @tag[:children] << {:tag_name=>:text, :value => results}
        end
      }
    end

    @tag = final_parent

    self
  end # === close

  public # =======================================================

  #
  # Ex:
  #   div.id(:main) {
  #     style {
  #       div.__._ { .. }
  #     }
  #   }
  #
  #   div {
  #     _.^(:sad) {
  #       color '#000'
  #     }
  #   }
  def _
    create :_
    if block_given?
      return(close { yield })
    end

    self
  end # === def _


end # === class WWW_App ==========================================

