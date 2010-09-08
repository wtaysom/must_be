require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  describe "#must_be" do
    context "when called with no arguments" do
      it "should notify if receiver is nil" do
        nil.must_be.should == nil
        should notify("nil.must_be, but is NilClass")
      end
      
      it "should notify if receiver is false" do
        false.must_be.should == false
        should notify("false.must_be, but is FalseClass")
      end
    end
    
    context "given 51 as receiver" do
      context "when called with no arguments" do
        it "should not notify" do
          51.must_be.should == 51
          should_not notify
        end
      end
      
      context "when called with Numeric" do
        it "should not notify" do
          51.must_be(Numeric).should == 51
          should_not notify
        end
      end
      
      context "when called with Float" do
        it "should notify" do
          51.must_be(Float).should == 51
          should notify("51.must_be(Float), but is Fixnum")
        end
      end
      
      context "when called with Comparable" do
        it "should not notify" do
          51.must_be(Comparable).should == 51
          should_not notify
        end
      end
      
      context "when called with Enumerable" do
        it "should notify" do
          51.must_be(Enumerable).should == 51
          should notify("51.must_be(Enumerable), but is Fixnum")
        end
      end
      
      context "when called with Hash, Kernel, Object" do
        it "should not notify" do
          51.must_be(Hash, Kernel, Object).should == 51
          should_not notify
        end
      end
      
      context "when called with String, Time, Array" do
        it "should notify" do
          51.must_be(String, Time, Array).should == 51
          should notify("51.must_be(String, Time, Array), but is Fixnum")
        end
      end
      
      context "when called with [1, 51]" do
        it "should notify" do
          51.must_be([1, 51]).should == 51
          should notify("51.must_be([1, 51]), but is Fixnum")
        end
      end
      
      context "when called with blocks" do
        let(:zerop) { lambda &:zero? }
        let(:oddp) { lambda &:odd? }
        
        context "when called with zerop" do
          it "should notify" do
            51.must_be(zerop).should == 51
            should notify
          end
        end
        
        context "when called with oddp" do
          it "should not notify" do
            51.must_be(oddp).should == 51
            should_not notify
          end
        end
        
        context "when called with zerop, oddp" do
          it "should not notify" do
            51.must_be(zerop, oddp).should == 51
            should_not notify
          end
        end
      end
    end
  end
  
  describe "#must_not_be" do
    context "when called with no arguments" do
      it "should not notify if receiver is nil" do
        nil.must_not_be.should == nil
        should_not notify
      end
      
      it "should not notify if receiver is false" do
        false.must_not_be.should == false
        should_not notify
      end
    end
    
    context "given 51 as receiver" do
      context "when called with no arguments" do
        it "should notify" do
          51.must_not_be.should == 51
          should notify("51.must_not_be, but is Fixnum")
        end
      end
      
      context "when called with Numeric" do
        it "should notify" do
          51.must_not_be(Numeric)
          should notify("51.must_not_be(Numeric), but is Fixnum")
        end
      end
      
      context "when called with Float" do
        it "should not notify" do
          51.must_not_be(Float).should == 51
          should_not notify
        end
      end
      
      context "when called with Comparable" do
        it "should notify" do
          51.must_not_be(Comparable)
          should notify("51.must_not_be(Comparable), but is Fixnum")
        end
      end
      
      context "when called with Enumerable" do
        it "should not notify" do
          51.must_not_be(Enumerable).should == 51
          should_not notify
        end
      end
      
      context "when called with Hash, Kernel, Object" do
        it "should notify" do
          51.must_not_be(Hash, Kernel, Object).should == 51
          should notify("51.must_not_be(Hash, Kernel, Object), but is Fixnum")
        end
      end
      
      context "when called with String, Time, Array" do
        it "should not notify" do
          51.must_not_be(String, Time, Array).should == 51
          should_not notify
        end
      end
      
      context "when called with [1, 51]" do
        it "should notify" do
          51.must_not_be([1, 51]).should == 51
          should_not notify
        end
      end
      
      context "when called with blocks" do
        let(:zerop) { lambda &:zero? }
        let(:oddp) { lambda &:odd? }
        
        context "when called with zerop" do
          it "should not notify" do
            51.must_not_be(zerop).should == 51
            should_not notify
          end
        end
        
        context "when called with oddp" do
          it "should notify" do
            51.must_not_be(oddp).should == 51
            should notify
          end
        end
        
        context "when called with zerop, oddp" do
          it "should notify" do
            51.must_not_be(zerop, oddp).should == 51
            should notify
          end
        end
      end
    end
  end
  
  shared_examples_for "*_be_a in case of bad arguments" do    
    context "when called with no arguments" do
      it "should raise ArgumentError" do
        expect do
          51.send(the_method_name)
        end.should raise_error(ArgumentError,
          "wrong number of arguments (0 for 1)")
      end
    end
    
    context "when called with more than one message" do
      it "should raise TypeError" do
        expect do
          51.send(the_method_name, Object, :extra_message, :usual_message)
        end.should raise_error(TypeError, "class or module required")
      end
    end
    
    context "when called with a non-module in the middle of the argument"\
        " list" do
      it "should raise TypeError" do
        expect do
          51.send(the_method_name, Object, :not_a_module, Kernel)
        end.should raise_error(TypeError, "class or module required")
      end
    end
    
    context "when called with just one non-module argument" do
      it "should raise TypeError" do
        expect do
          51.send(the_method_name, :not_a_module)
        end.should raise_error(TypeError, "class or module required")
      end
    end    
  end
  
  describe "#must_be_a" do
    let(:the_method_name) { :must_be_a }
    it_should_behave_like "*_be_a in case of bad arguments"
    
    context "given 51 as receiver" do
      it "should notify if called with Float" do
        51.must_be_a(Float)
        should notify("51.must_be_a(Float), but is a Fixnum")
      end
      
      context "after disabling" do
        before_disable_after_enable
        
        it "should not notify if called with a Float" do
          51.must_be_a(Float)
          should_not notify
        end
      end
      
      it "should not notify if called with Kernel and Comparable" do
        51.must_be_a(Kernel, Comparable)
        should_not notify
      end
      
      it "should notify if called with Float and :message" do
        51.must_be_a(Float, :message)
        should notify("51.must_be_a(Float, :message), but is a Fixnum")
      end
    end
  end
  
  describe "#must_not_be_a" do
    let(:the_method_name) { :must_not_be_a }
    it_should_behave_like "*_be_a in case of bad arguments"
    
    context "given 51 as receiver" do
      it "should notify if called with Float and Enumerable" do
        51.must_not_be_a(Float, Enumerable)
        should_not notify
      end
      
      it "should notify if called with Kernel, Comparable" do
        51.must_not_be_a(Kernel, Comparable)
        should notify("51.must_not_be_a(Kernel, Comparable), but is a Fixnum")
      end
      
      it "should notify if called with Numeric and :message" do
        51.must_not_be_a(Numeric, :message)
        should notify("51.must_not_be_a(Numeric, :message), but is a Fixnum")
      end
    end
  end
  
  shared_examples_for "*_be_in in case of bad arguments" do
    context "when called with :does_not_respond_to_include?" do
      it "should raise NoMethodError" do
        expect do
          "hi".send(the_method_name, :does_not_respond_to_include?)
        end.should raise_error(NoMethodError)
      end
    end
  end
  
  describe "#must_be_in" do
    let(:the_method_name) { :must_be_in }
    it_should_behave_like "*_be_in in case of bad arguments"
    
    context "given \"hi\" as receiver" do
      context "when called with empty array" do
        it "should notify" do
          "hi".must_be_in([]).should == "hi"
          should notify(%{"hi".must_be_in([])})
        end
      end
      
      context "when called with an array which does not include it" do
        it "should notify" do
          "hi".must_be_in(["happy", "helper", "hiccup"]).should == "hi"
          should notify(
            %{"hi".must_be_in(["happy", "helper", "hiccup"])})
        end
      end
      
      context "when called with a range which includes it" do
        it "should not notify" do
          "hi".must_be_in("ah".."oh").should == "hi"
          should_not notify
        end
      end
      
      context "when called with a string which includes it" do
        it "should not notify" do
          "hi".must_be_in("wishing").should == "hi"
          should_not notify
        end
      end
      
      context "when called with no arguments" do
        it "should notify" do
          :yep.must_be_in
          should notify(":yep.must_be_in")
        end
      end
      
      context "when called with multiple arguments" do
        it "should not notify if any argument equals the receiver" do
          :yep.must_be_in(:okay, :yep, :fine)
          should_not notify
        end
        
        it "should notify if no argument equals the receiver" do
          :yep.must_be_in(:nope, :sorry, :negatory)
          should notify(":yep.must_be_in(:nope, :sorry, :negatory)")
        end
      end
    end
  end
  
  describe "#must_not_be_in" do
    let(:the_method_name) { :must_not_be_in }
    it_should_behave_like "*_be_in in case of bad arguments"
    
    context "given \"hi\" as receiver" do
      context "when called with empty array" do
        it "should not notify" do
          "hi".must_not_be_in([]).should == "hi"
          should_not notify
        end
      end
      
      context "when called with an array which does not include it" do
        it "should not notify" do
          "hi".must_not_be_in(["happy", "helper", "hiccup"]).should == "hi"
          should_not notify
        end
      end
      
      context "when called with a range which includes it" do
        it "should notify" do
          "hi".must_not_be_in("ah".."oh").should == "hi"
          should notify(%{"hi".must_not_be_in("ah".."oh")})
        end
      end
      
      context "when called with a string which includes it" do
        it "should notify" do
          "hi".must_not_be_in("wishing").should == "hi"
          should notify(%{"hi".must_not_be_in("wishing")})
        end
      end
      
      context "when called with no arguments" do
        it "should not notify" do
          :yep.must_not_be_in
          should_not notify
        end
      end
      
      context "when called with multiple arguments" do
        it "should notify if any argument equals the receiver" do
          :yep.must_not_be_in(:okay, :yep, :fine)
          should notify(":yep.must_not_be_in(:okay, :yep, :fine)")
        end
        
        it "should not notify if no argument equals the receiver" do
          :yep.must_not_be_in(:nope, :sorry, :negatory)
          should_not notify
        end
      end
    end
  end
  
  it_should_have_must_be_value_assertion :must_be_nil, nil
  it_should_have_must_not_be_value_assertion :must_not_be_nil, nil
  it_should_have_must_be_value_assertion :must_be_true, true
  it_should_have_must_be_value_assertion :must_be_false, false
  
  describe "#must_be_boolean" do
    it "should not notify if receiver is true" do
      true.must_be_boolean.should == true
      should_not notify
    end
    
    it "should not notify if receiver is false" do
      false.must_be_boolean.should == false
      should_not notify
    end
    
    it "should notify if receiver is nil" do
      nil.must_be_boolean.should == nil
      should notify("nil.must_be_boolean")
    end
    
    it "should notify if receiver is zero" do
      0.must_be_boolean.should == 0
      should notify("0.must_be_boolean")
    end
  end
  
  shared_examples_for "*_be_close in case of bad arguments" do
    it "should raise ArgumentError if delta cannot be compared" do
      expect do
        200.0.send(the_method_name, 2.0, :a_little)
      end.should raise_error(ArgumentError)
    end
    
    it "should raise TypeError if expected cannot be subtracted from"\
        " receiver" do
      expect do
        200.0.send(the_method_name, :some)
      end.should raise_error(TypeError)
    end

    it "should raise NoMethodError if receiver does not respond to `-'" do
      expect do
        :lots.send(the_method_name, 2.0)
      end.should raise_error(NoMethodError)
    end

    it "should rasie NoMethodError if `receiver - expected' does not"\
        " respond to `abs'" do
      expect do
        Time.new.send(the_method_name, 2.0, :five)
      end.should raise_error(NoMethodError)
    end
  end
  
  describe "#must_be_close" do
    let(:the_method_name) { :must_be_close }
    it_should_behave_like "*_be_close in case of bad arguments"
    
    it "should not notify if receiver is the same" do
      2.0.must_be_close(2.0).should == 2.0
      should_not notify
    end
    
    it "should not notify if receiver is a bit greater" do
      2.01.must_be_close(2.0).should == 2.01
      should_not notify
    end
    
    it "should not notify if receiver is a bit less" do
      1.91.must_be_close(2.0).should == 1.91
      should_not notify
    end
    
    it "should notify if receiver is much greater" do
      200.0.must_be_close(2.0, 20.0).should == 200.0
      should notify("200.0.must_be_close(2.0, 20.0)")
    end
    
    it "should notify if receiver is much less" do
      -200.0.must_be_close(2.0, 20.0).should == -200.0
      should notify("-200.0.must_be_close(2.0, 20.0)")
    end
  end
  
  describe "#must_not_be_close" do
    let(:the_method_name) { :must_not_be_close }
    it_should_behave_like "*_be_close in case of bad arguments"
    
    it "should notify if receiver is the same" do
      2.0.must_not_be_close(2.0).should == 2.0
      should notify("2.0.must_not_be_close(2.0, 0.1)")
    end
    
    it "should notify if receiver is a bit greater" do
      2.01.must_not_be_close(2.0).should == 2.01
      should notify("2.01.must_not_be_close(2.0, 0.1)")
    end
    
    it "should notify if receiver is a bit less" do
      1.91.must_not_be_close(2.0).should == 1.91
      should notify("1.91.must_not_be_close(2.0, 0.1)")
    end
    
    it "should not notify if receiver is much greater" do
      200.0.must_not_be_close(2.0, 20.0).should == 200.0
      should_not notify
    end
    
    it "should not notify if receiver is much less" do
      -200.0.must_not_be_close(2.0, 20.0).should == -200.0
      should_not notify
    end
  end
end

### Proc Case Equality Patch ###

describe "case equality patch" do
  describe "Proc#===" do
    it "should work the same as Proc#call" do
      is_less_than_three = lambda {|x| x < 3 }
      is_less_than_three.should === 2
      is_less_than_three.should_not === 7
      
      is_even = lambda &:even?
      is_even.should === 2
      is_even.should_not === 7
    end
    
    if RUBY_VERSION < "1.9"
      it "should alias Proc#call" do
        Proc.instance_method(:===).should == Proc.instance_method(:call)
      end
    end
  end
end