
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
      background                 bottom                     font_variant_position      quotes
      background_attachment      box_decoration_break       font_weight                resize
      background_clip            box_shadow                 height                     right
      background_color           box_sizing                 hyphens                    tab_size
      background_image           clear                      icon                       table_layout
      background_origin          clip                       image_orientation          text_align
      background_position        clip_path                  image_rendering            text_align_last
      background_repeat          color                      image_resolution           text_combine_horizontal
      background_size            column_count               ime_mode                   text_decoration
      border                     column_fill                justify_content            text_decoration_color
      border_bottom              column_gap                 left                       text_decoration_line
      border_bottom_color        column_rule                letter_spacing             text_decoration_style
      border_bottom_left_radius  column_rule_color          line_height                text_indent
      border_bottom_right_radius column_rule_style          list_style                 text_orientation
      border_bottom_style        column_rule_width          list_style_image           text_overflow
      border_bottom_width        column_span                list_style_position        text_rendering
      border_collapse            column_width               list_style_type            text_shadow
      border_color               columns                    margin                     text_size_adjust
      border_image               counter_increment          margin_bottom              text_transform
      border_image_outset        counter_reset              margin_left                text_underline_position
      border_image_repeat        cursor                     margin_right               top
      border_image_slice         direction                  margin_top                 touch_action
      border_image_source        display                    marks                      transform
      border_image_width         empty_cells                mask                       transform_origin
      border_left                filter                     mask_type                  transform_style
      border_left_color          float                      max_height                 transition
      border_left_style          font                       max_width                  transition_delay
      border_left_width          font_family                min_height                 transition_duration
      border_radius              font_feature_settings      min_width                  transition_property
      border_right               font_kerning               opacity                    transition_timing_function
      border_right_color         font_language_override     order                      unicode_bidi
      border_right_style         font_size                  orphans                    unicode_range
      border_right_width         font_size_adjust           overflow                   vertical_align
      border_spacing             font_stretch               overflow_wrap              visibility
      border_style               font_style                 overflow_x                 white_space
      border_top                 font_synthesis             overflow_y                 widows
      border_top_color           font_variant               padding                    width
      border_top_left_radius     font_variant_alternates    padding_bottom             word_break
      border_top_right_radius    font_variant_caps          padding_left               word_spacing
      border_top_style           font_variant_east_asian    padding_right              word_wrap
      border_top_width           font_variant_ligatures     padding_top                z_index
      border_width               font_variant_numeric       position
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
    #     div.^(:bad).__.div {
    #     }
    #
    def __
      fail "Can only be used inside :style tag" unless ancestor?(:style)

      if !@tag || (@tag[:tag_name] == :group || @tag[:tag_name] == :groups)
        fail "Can only be used after an HTML element is created: #{@tag[:tag_name].inspect}"
      end

      @tag[:__] = true
      go_up
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
    #   link.href('/file')./
    #
    def / *args
      fail "No block allowed here." if block_given?

      case args.size
      when 0
        close
      when 1
        self
      else
        fail ::ArgumentError, "Unknown args: #{args.inspect[0,50]}"
      end
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

      metaphor = (de_ref(tag) || {}.freeze)

      final = case

              when type == :full && tag?(metaphor, :group)
                css = metaphor[:children].inject([]) { |memo, c|
                  if !(tag?(c, :group)) && !c[:__parent]
                    memo << css_selector(c, :full)
                  end
                  memo
                }

                if css
                  css.join COMMA
                else
                  nil
                end

              when tag?(metaphor, :style)
                p = metaphor[:parent]
                if p
                  css_selector p, type
                end

              when type == :full && parent?(metaphor, :group)
                grand_parent = metaphor[:parent][:parent]
                grand_css    = grand_parent && css_selector(grand_parent, :full)
                use_grand    = !(metaphor[:__] && metaphor[:__children].detect { |e| tag?(e, :_) })

                if grand_css && use_grand
                  grand_css.split(COMMA).map { |css|
                    css << SPACE << css_selector(metaphor, :tag)
                  }.join COMMA
                else
                  css_selector metaphor, :tag
                end

              when type == :tag
                id = metaphor[:id]
                name = if id
                         '#' << Clean.html_id(id).to_s
                       else
                         metaphor[:tag_name].to_s
                       end

                if metaphor[:class]
                  name << '.'.freeze
                  name.<<(
                    metaphor[:class].map { |name|
                      Clean.css_class_name(name.to_s)
                    }.join('.'.freeze)
                  )
                end

                if metaphor[:pseudo]
                  name << ":#{metaphor[:pseudo]}"
                end

                if tag[:__]
                  name << SPACE << tag[:__children].map { |c|
                    css_selector(c, :tag)
                  }.join(SPACE)
                end

                name = if name.empty?
                         nil
                       else
                         name
                       end

              when type == :ancestor
                if metaphor[:id]
                  nil
                else
                  selectors = []
                  p         = metaphor[:parent]
                  while p
                    selectors.unshift(css_selector(p, :tag)) unless [:style, :group].freeze.include?(p[:tag_name])
                    p = p[:id] ? nil : p[:parent]
                  end # === while

                  selectors.compact.join(SPACE)
                end

              else
                [css_selector(metaphor, :ancestor), css_selector(metaphor, :tag)].compact.join SPACE
              end

      return nil if !final || final.empty?
      final.gsub(' _!:'.freeze, ':'.freeze)
    end

    private # ==================================

    def pseudo name
      case
      when ancestor?(:groups) && @tag[:closed]
        # Ex:
        #   style {
        #     div   { ... }
        #     _link { ... }
        create :group
        create :_!

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
      if !@tag
        self._
      end
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
