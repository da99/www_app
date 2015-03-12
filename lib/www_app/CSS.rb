
class WWW_App

  module CSS
    COMMA = ", ".freeze

    AT_RULES    = [ 'font-face', 'media' ]

    # === From:
    # https://developer.mozilla.org/en-US/docs/Web/CSS/Pseudo-classes
    PSEUDO = %w[
     active checked default dir() disabled
     empty enabled
     first first-child first-of-type fullscreen focus
     hover
     indeterminate in-range invalid
     lang() last-child last-of-type left link
     not() nth-child() nth-last-child() nth-last-of-type() nth-of-type()
     only-child only-of-type optional out-of-range
     read-only read-write required right root
     scope
     target
     valid visited
    ].select { |name| name[/\A[a-z0-9\-]+\Z/] }.map { |name| name.gsub('-', '_').to_sym }

      # From: Sanitize::Config::RELAXED[:css][:properties]
    PROPERTIES = %w[
      background                 bottom                     font_variant_numeric       position
      background_attachment      box_decoration_break       font_variant_position      quotes
      background_clip            box_shadow                 font_weight                resize
      background_color           box_sizing                 height                     right
      background_image           clear                      hyphens                    tab_size
      background_origin          clip                       icon                       table_layout
      background_position        clip_path                  image_orientation          text_align
      background_repeat          color                      image_rendering            text_align_last
      background_size            column_count               image_resolution           text_combine_horizontal
      border                     column_fill                ime_mode                   text_decoration
      border_bottom              column_gap                 justify_content            text_decoration_color
      border_bottom_color        column_rule                left                       text_decoration_line
      border_bottom_left_radius  column_rule_color          letter_spacing             text_decoration_style
      border_bottom_right_radius column_rule_style          line_height                text_indent
      border_bottom_style        column_rule_width          list_style                 text_orientation
      border_bottom_width        column_span                list_style_image           text_overflow
      border_collapse            column_width               list_style_position        text_rendering
      border_color               columns                    list_style_type            text_shadow
      border_image               content                    margin                     text_transform
      border_image_outset        counter_increment          margin_bottom              text_underline_position
      border_image_repeat        counter_reset              margin_left                top
      border_image_slice         cursor                     margin_right               touch_action
      border_image_source        direction                  margin_top                 transform
      border_image_width         display                    marks                      transform_origin
      border_left                empty_cells                mask                       transform_style
      border_left_color          filter                     mask_type                  transition
      border_left_style          float                      max_height                 transition_delay
      border_left_width          font                       max_width                  transition_duration
      border_radius              font_family                min_height                 transition_property
      border_right               font_feature_settings      min_width                  transition_timing_function
      border_right_color         font_kerning               opacity                    unicode_bidi
      border_right_style         font_language_override     order                      unicode_range
      border_right_width         font_size                  orphans                    vertical_align
      border_spacing             font_size_adjust           overflow                   visibility
      border_style               font_stretch               overflow_wrap              white_space
      border_top                 font_style                 overflow_x                 widows
      border_top_color           font_synthesis             overflow_y                 width
      border_top_left_radius     font_variant               padding                    word_break
      border_top_right_radius    font_variant_alternates    padding_bottom             word_spacing
      border_top_style           font_variant_caps          padding_left               word_wrap
      border_top_width           font_variant_east_asian    padding_right              z_index
      border_width               font_variant_ligatures     padding_top
    ].map(&:to_sym)

    PROPERTIES.each { |name|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name} *args
          alter_css_property(:#{name}, *args)
          block_given? ?
            close { yield } :
            self
        end
      EOF
    }

    PSEUDO.each { |name|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def _#{name} *args
          pseudo :#{name}, *args
          block_given? ?
            close { yield } :
            self
        end
      EOF
    }

    #
    # Ex:
    #   style {
    #     div.__div {
    #     }
    #
    def __
      fail "Can only be used inside :style tag" unless ancestor?(:style)
      if !@tag || (@tag[:tag_name] == :group || @tag[:tag_name] == :groups)
        fail "Can only be used after an HTML element is created: #{@tag[:tag_name].inspect}"
      end

      @tag[:__] = true
      self
    end

    #
    # Example:
    #   style {
    #     a._link / a._hover {
    #       ...
    #     }
    #   }
    #
    def / app
      fail "No block allowed here." if block_given?
      self
    end

    #
    # Example:
    #   css_selector
    #   css_selector tag
    #   css_selector :full || :tag || :ancestor
    #   css_selector tag, :full || :tag || :ancestor
    #
    def css_selector *args
      tag  = @tag
      type = :full
      args.each { |a|
        case
        when a.is_a?(Symbol)
          type = a
        else
          tag = a
        end
      }

      real_tag = (de_ref(tag) || {}.freeze)

      if tag[:tag_name] == :_
        new_tag = {
          :tag_name => real_tag[:tag_name] || :body,
          :id       => tag[:id] || real_tag[:id],
          :class    => tag[:class] || real_tag[:class],
          :parent   => real_tag[:parent],
          :pseudo   => tag[:pseudo] || real_tag[:pseudo]
        }
        tag = new_tag
      end

      final = case

              when type == :full && tag?(real_tag, :group)
                css = real_tag[:children].inject([]) { |memo, c|
                  if !(tag?(c, :group))
                    memo << css_selector(c, :full)
                  end
                  memo
                }

                if css
                  css.join COMMA
                else
                  nil
                end

              when tag?(real_tag, :style)
                p = real_tag[:parent]
                if p
                  css_selector p, type
                end

              when type == :full && parent?(real_tag, :group)
                grand_parent = real_tag[:parent][:parent]
                grand_css = grand_parent && css_selector(grand_parent, :full)
                if grand_css
                  grand_css.split(COMMA).map { |css|
                    css << SPACE << css_selector(real_tag, :tag)
                  }.join COMMA
                else
                  css_selector(:tag, real_tag)
                end

              when type == :tag

                name = real_tag[:tag_name].to_s

                id = tag[:id] || real_tag[:id]
                if id
                  name << '#'.freeze << Clean.html_id(id).to_s
                end

                if tag[:class]
                  name << '.'.freeze 
                  name.<<(
                    tag[:class].map { |name|
                      Clean.css_class_name(name)
                    }.join('.'.freeze)
                  )
                end

                if tag[:pseudo]
                  name << ":#{tag[:pseudo]}"
                end

                name = nil if name.empty?
                name

              when type == :ancestor
                if tag[:id]
                  nil
                else
                  selectors = []
                  p         = tag[:parent]
                  while p
                    selectors.unshift(css_selector(p, :tag)) unless [:style, :group].freeze.include?(p[:tag_name])
                    p = p[:parent]
                  end # === while

                  selectors.compact.join(SPACE)
                end

              else
                [css_selector(tag, :ancestor), css_selector(tag, :tag)].compact.join SPACE
              end

      return nil if !final || final.empty?
      final
    end

    private # ==================================

    def pseudo name
      case
      when ancestor?(:groups) && @tag[:closed]
        #
        # Ex:
        #   style {
        #     div   { ... }
        #     _link { ... }
        #
        create :group
        create :__

      when @tag[:pseudo] && !@tag[:closed]
        # Ex:
        #   a._link._visited { ... }
        fail "Applying two pseudos at the same element."

      end # === case

      @tag[:pseudo] = name
      block_given? ?
        close { yield } :
        self
    end

    def alter_css_property name, *args
      @tag[:css] ||= {}
      @tag[:css][name] = args.size == 1 ? args.first : args
      self
    end

    def style
      create :style, :type=>'text/css', :groups=>true
      close { yield }
    end

  end # === module CSS ==============
end # === class WWW_App =============
