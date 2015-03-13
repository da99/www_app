
require 'Bacon_Colored'
require 'www_app'
require 'pry'
require "differ"
require "sanitize"
require "escape_escape_escape"

Differ.format = :color

TEMPLATE = File.read(__FILE__).
  split('__END__').
  last.
  strip

def norm ugly
  ugly.
    strip.
    split("\n").
    map(&:strip).
    join("\n")
end

def strip_each_line str
  str.split("\n").map(&:strip).join "\n"
end

def get_content tag, html
  ( html.match(/\<#{tag}\>(.+)\<\/#{tag}\>/)[1] || '' ).
    split("\n").
    map(&:strip).
    join "\n"
end

def style html
  get_content 'style', html
end

def script html
  get_content 'script', html
end

def body html
  get_content 'body', html
end

def to_html h
  TEMPLATE.gsub(/!([a-z\_]+)/) { |sub|
    key = $1.to_sym
    case key
    when :style
      Sanitize::CSS.stylesheet(
        (h[key] || '').strip,
        Escape_Escape_Escape::CONFIG
      )
    when :body
      Escape_Escape_Escape.html(h[key] || '')
    when :title
      Escape_Escape_Escape.html(h[key] || '[No Title]')
    else
      fail "Unknown key: #{key.inspect}"
    end
  }
end

def should_equal target, &blok
  a = norm(WWW_App.new(&blok).to_html)
  t = norm( target )
  return(a.should == t) if a == t

  puts " ======== ACTUAL =========="
  puts a
  puts " ======== TARGET =========="
  puts t
  puts " =========================="
  puts Differ.diff_by_word(a,t)
  puts " =========================="
  fail "No match"
end

module Bacon
  class Context

    def target *args
      @target_args = args
    end

    def actual vals = {}, &blok
      if !@target_args
        return WWW_App.new(&blok).to_html(vals)
      end

      include_tag = if @target_args.first == :outer
                      !!@target_args.shift
                    end

      @target_args.unshift(:body) if @target_args.size == 1
      norm_target   = norm @target_args.last

      tag           = @target_args.first
      html          = WWW_App.new(&blok).to_html(vals)
      section       = case
                      when include_tag
                        html[/(<#{tag}[^\>]*>.+<\/#{tag}>)/m] && $1
                      else
                        html[/<#{tag}[^\>]*>(.+)<\/#{tag}>/m] && $1
                      end || html
      norm_actual   = norm section

      if norm_target != norm_actual
        puts " ======== TARGET =========="
        puts norm_target
        puts " ======== ACTUAL =========="
        puts norm_actual
        puts " ====== ORIGINAL ACTUAL ==="
        puts html
        puts " =========================="
      end

      norm_actual.should == norm_target
    end

  end # === class Context ===
end # === module Bacon ===

class WWW_App_Test

  def initialize applet, output
    @app    = applet
    @err    = nil
    @test   = WWW_App.new("__main_test___", output)
    @test.extend Computers
    @test.send :test_app, @app
  end

  def run
    begin
      @app.run
    rescue Object => e
      fail_expected = @test.tokens.detect { |v|
        v.is_a?(String) && WWW_App.standard_key(v) == "SHOULD RAISE"
      }
      raise e unless fail_expected
      @test.send :test_err, e
    end
    @test.run
  end

  module Computers

    class << self
      def aliases
        @map ||= {}
      end
    end # === class self

    private
    def test_app app = :none
      if app != :none
        @test_app = app
      end
      @test_app
    end

    def test_err e = :none
      if e != :none
        @test_err = e
      end
      @test_err
    end


    public
    aliases[:value_should_equals_equals] = "value should =="
    def value_should_equals_equals sender, to, args
      name = sender.stack.last
      target = args.last
      @test_app.get(name).should == target
    end

    def should_raise sender, to, args
      err_name = args.last
      @test_err.message.should.match /#{Regexp.escape err_name}/
      @test_err.message
    end

    def message_should_match sender, to, args
      str_regex = args.last
      msg = sender.stack.last
      msg.should.match /#{Regexp.escape str_regex}/i
    end

    aliases[:stack_should_equal_equal] = "stack should =="
    def stack_should_equal_equal sender, to, args
      @test_app.stack.should == args
    end

    def should_not_raise sender, to, args
      @err.should == nil
    end

    aliases[:last_console_message_should_equal_equal] = "last console message should =="
    def last_console_message_should_equal_equal sender, to, args
      @test_app.console.last.should == args.last
    end

    aliases[:console_should_equal_equal] = "console should =="
    def console_should_equal_equal sender, to, args
      @test_app.console.should == args
    end
  end # === module Computers

end # === class


__END__
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <title>!title</title>
    <style type="text/css">
      !style
    </style>
  </head>
  <body>!body</body>
</html>



