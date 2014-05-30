
require 'Bacon_Colored'
require 'www_applet'
require 'pry'

class WWW_Applet_Test

  def initialize applet, output
    @applet = applet
    @err    = nil
    @test   = WWW_Applet.new(output)

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
