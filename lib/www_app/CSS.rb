
class WWW_App

  AT_RULES    = [ 'font-face', 'media' ]

  module CSS

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
    CSS_PROPERTIES = %w[
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

    CSS_PROPERTIES.each { |name|
      str_name = name.to_s.gsub('_', '-')
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def #{name} *args
          if block_given?
            alter_css_property(:#{name}, *args) {
              yield
            }
          else
            alter_css_property(:#{name}, *args)
          end
        end
      EOF
    }

    PSEUDO.each { |name|
      eval <<-EOF, nil, __FILE__, __LINE__ + 1
        def _#{name} *args
          if block_given?
            pseudo(:#{name}, *args) { yield }
          else
            pseudo :#{name}, *args
          end
        end
      EOF
    }

    def pseudo name
      case
      when tag[:closed]
        create :group
        create :__

      when tag[:pseudo] && !tag[:closed]
        go_up_to :group
        create :__

      end # === case

      tag[:pseudo] = name
      if block_given?
        close { yield }
      end
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

    def _
      case
      when tag[:type] == :group
        create :_
      when tag[:groups]
        create :group
        create :_
      else
        tag[:_] = true
      end

      self
    end

  end # === module CSS

  private # ==================================

  def style
    create :styles, :groups=>true
    close { yield }
    nil
  end

end # === class WWW_App
