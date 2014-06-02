
require 'Bacon_Colored'
require 'www_applet'
require 'pry'

class WWW_Applet_Test

  module Computers
    def write_computer name, l
      @computers[name] = [l]
    end
  end # === module Computers

  def initialize applet, output
    @applet = applet
    @err    = nil
    @test   = WWW_Applet.new("__main_test___", output)
    @test.extend Computers

    @test.write_computer "value should ==", lambda { |o,n,v|
      name = o.stack.last
      target = o.fork_and_run(n,v).stack.last
      @applet.read_value(name).should == target
    }

    @test.write_computer "should raise", lambda { |o,n,v|
      target = o.fork_and_run(n,v).stack.last
      @err.class.to_s.split('::').last.should == target
      @err.message
    }

    @test.write_computer "message should match", lambda { |o,n,v|
      str_regex = o.fork_and_run(n,v).stack.last
      msg = o.stack.last
      msg.should.match /#{Regexp.escape str_regex}/i
    }

    @test.write_computer "stack should ==", lambda { |o,n,v|
      @applet.stack.should == o.fork_and_run(n,v).stack
    }

    @test.write_computer "should not raise", lambda { |o,n,v|
      @err.should == nil
    }

    @test.write_computer "last console message should ==", lambda { |o,n,v|
      @applet.console.last.should == o.fork_and_run(n,v).stack.last
    }
  end

  def run
    begin
      @applet.run
    rescue Object => e
      @err = e
    end
    @test.run
  end

end # === class
