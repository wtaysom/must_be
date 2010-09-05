require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  describe "Module#attr_typed" do
    context "when updating" do
      module ModuleWhoUsesAttrTyped
        attr_typed :int, Bignum, Fixnum
        attr_typed :positive_int, Bignum, Fixnum do |n|
          n > 0
        end
        attr_typed :non_nil
      end
      
      class UsesAttrTyped
        include ModuleWhoUsesAttrTyped
        
        attr_typed :float, Float
        attr_typed :empty, &:empty?
        attr_typed :collection, Array, Hash, Range
      end
      
      subject { UsesAttrTyped.new }
      
      context "against one type constraint" do
        it "should not notify if new value has the type" do
          subject.float = 23.3
          subject.float.should == 23.3
          should_not notify
        end
        
        it "should notify if new value does not have the type" do
          subject.float = 23
          should notify("attribute `float' is typed as Float,"\
            " but value 23 is a Fixnum")
        end
      end
      
      context "against two type constraints" do
        it "should not notify if new value matches one of the constraints" do
          subject.int = 56
          should_not notify
        end
        
        it "should notify if new value does not match either constraint " do
          subject.int = 56.6
          should notify("attribute `int' is typed as Bignum or Fixnum,"\
            " but value 56.6 is a Float")
        end
      end
      
      context "against multiple type constraints" do
        it "should not notify if new value matches last constraint" do
          subject.collection = 1..3
          should_not notify
        end
        
        it "should notify if new value matches none of the constraints" do
          subject.collection = :scalar
          should notify("attribute `collection' is typed as one of"\
            " [Array, Hash, Range], but value :scalar is a Symbol")
        end
      end
      
      context "against a block constraint" do
        it "should not notify if block[value] is true" do
          subject.empty = []
          should_not notify
        end
        
        it "should notify if block[value] is not true" do
          subject.empty = [:not, :empty]
          should notify("attribute `empty' cannot be [:not, :empty]")
        end
      end
      
      context "against two types and a block constraint" do
        it "should not notify if new value matches one of the types"\
            " and block[value] is true" do
          subject.positive_int = 45
          should_not notify
        end
        
        it "should notify if new value does not match one of the types" do
          subject.positive_int = 87.6
          should notify("attribute `positive_int' is typed as Bignum"\
            " or Fixnum, but value 87.6 is a Float")
        end
        
        it "should notify if block[value] is not true" do
          subject.positive_int = -11
          should notify("attribute `positive_int' cannot be -11")
        end
      end
      
      context "against no listed contraint" do
        it "should not notify if new value is non-nil" do
          subject.non_nil = false
          should_not notify
        end
        
        it "should notify if new value is nil" do
          subject.non_nil = nil
          should notify("attribute `non_nil' cannot be nil")
        end
      end
    end
    
    context "when called twice for the same symbol" do
      class AttrTypedCalledTwiceForSameSymbol
        attr_typed :twice, Symbol
        attr_typed :twice, String
      end
      
      subject { AttrTypedCalledTwiceForSameSymbol.new }
      
      it "second call should override first" do
        subject.twice = :symbol
        should notify("attribute `twice' is typed as String,"\
          " but value :symbol is a Symbol")
      end
    end
    
    context "when called with bad argument" do
      subject { Class.new }
      
      describe "(symbol)" do
        it "should raise if symbol cannot be converted #to_sym" do
          expect do
            subject.attr_typed [], Object
          end.should raise_error(TypeError, "[] is not a symbol")
        end
        
        it "should raise if symbol is a Fixnum" do
          expect do
            subject.attr_typed 111, Object
          end.should raise_error(TypeError, "111 is not a symbol")
        end
        
        it "should be fine if symbol is a String" do
          expect do
            subject.attr_typed "string", Object
          end.should_not raise_error
        end
      end
      
      describe "(types)" do
        it "should raise if any type is an Array" do
          expect do
            subject.attr_typed :prop, [Array, Object]
          end.should raise_error(TypeError, "class or module required")
        end
        
        it "should raise if any type is a String" do
          expect do
            subject.attr_typed :prop, "string"
          end.should raise_error(TypeError, "class or module required")
        end
      end
    end
  end
end