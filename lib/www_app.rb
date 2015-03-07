

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

  attr_reader :tag, :tags
  def initialize &blok
    @mustache          = nil
    @html_ids          = {}

    @tags = []
    @tag  = nil

    create(:body) do
      instance_eval &blok
    end

    freeze
  end

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

    if block_given?
      results = yield

      results = nil if tag?(:script)

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

    @tag = final_parent

    self
  end # === close

  def in_tag t
    orig = @tag
    @tag = t
    yield
    @tag = orig
    nil
  end

  def alter_css_property name, *args
    @tag[:css] ||= {}
    @tag[:css][name] = args
    self
  end

end # === class WWW_App ==========================================

