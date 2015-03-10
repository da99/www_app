

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

    instance_eval &blok
  end

  def SPACE indent
    ' '.freeze * indent
  end

  def lang name
    in_tag(:html) {
      @tag[:lang] = name.to_s.downcase.gsub(/[^a-z0-9\_\-]+/, ''.freeze)
      @tag[:lang] = 'en' if @tag[:lang].empty?
    }
    self
  end

  def find tag_name
    case tag_name
    when :html, :body
      @tags.detect { |t| t[:tag_name] == tag_name }
    when :head
      find(:html)[:children].detect { |t| t[:tag_name] == tag_name }
    else
      tags = @tags.dup
      found  = nil
      while !found && !tags.empty?
        found = tags.shift
        if found[:tag_name] != tag_name
          if found[:children]
            tags = found[:children].concat tags
          end
          found = nil
        end
      end
    end
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

  def tag_or_ancestor? name
    !!find_nearest(name)
  end

  def ancestor? name
    !!(find_ancestor name)
  end

  def find_nearest name
    return @tag if tag?(name)
    find_ancestor name
  end

  def find_ancestor name
    ancestor = parent
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

  def parent?
    !!parent
  end

  def parent
    tag && tag[:parent]
  end

  def doc!
    if @tags.empty?
      create :text, :skip_escape=>true, :closed=>true, :value=>"<!DOCTYPE html>\n".freeze
      go_up
      create :html, :lang=>"en"
      create :head
      go_up
      create :body
    else
      head = find(:head)
      body = find(:body)
      if !head || !body
        fail "HTML elements in wrong place."
      end
    end

    self
  end

  def in_tag t
    case

    when t.is_a?(::Symbol)
      doc!
      in_tag(find(t)) {
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
    # === If:
    #   we are creating an HTML element
    #   within a group, then we either start
    #   a new group or stay here.
    if HTML::TAGS.include?(name) && tag_or_ancestor?(:groups)
      if tag?(:groups)
        create :group
      else
        # Example: div.id(:main)._.div.^(:my_class)
        stay_or_go_up_to_if_exists(:group) if tag && !tag[:_]
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
          fail Invalid_Type, results[:tag_name].inspect
        end

        if (results.is_a?(::Hash) && results[:tag_name] == :string) || results.is_a?(::String) || results.is_a?(::Symbol)
          tag[:children] ||= []
          tag[:children] << {:tag_name=>:text, :value => results}
        end
      }
    end

    @tag = final_parent

    self
  end # === close

end # === class WWW_App ==========================================

