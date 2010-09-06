require 'spec_helper'

describe MustBe do
  include MustBeExampleHelper
  
  shared_examples_for "*_raise in case of bad arguments" do
    context "when called with an exception type and something other"\
        " than nil, a string, or a regexp" do
      it "should raise TypeError" do
        expect do
          :it.must_raise(RangeError, :not_nil_string_or_regexp) {}
        end.should raise_error(TypeError, "nil, string, or regexp required")
      end
    end
  end
  
  describe "#must_raise" do
    it_should_behave_like "*_raise in case of bad arguments"
    
    context "when called with no arguments" do
      it "should not notify if any Exception is raised" do
        expect do
          :it.must_raise { raise Exception }
        end.should raise_error(Exception)
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        called = false
        :it.must_raise{called = true; :result}.should == :result
        called.should be_true
        should notify(":it.must_raise {}, but nothing was raised")
      end
    end
    
    context "when called with an Exception type" do
      it "should not notify if an Exception of the same type is raised" do
        expect do
          :it.must_raise(TypeError) { raise TypeError }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(TypeError) {}
        should notify(":it.must_raise(TypeError) {}, but nothing was raised")
      end
      
      it "should notify if a different Exception type is raised" do
        expect do
          :it.must_raise(TypeError) { raise ArgumentError }
        end.should raise_error
        should notify(":it.must_raise(TypeError) {},"\
          " but ArgumentError was raised")
      end
    end
    
    context "when called with String" do
      it "should not notify if an error with the same message is raised" do
        expect do
          :it.must_raise("message") { raise "message" }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise("message") {}
        should notify(":it.must_raise(\"message\") {}, but nothing"\
          " was raised")
      end
      
      it "should notify if an Exception with a different message is raised" do
        expect do
          :it.must_raise("message") { raise "wrong" }
        end.should raise_error
        should notify(":it.must_raise(\"message\") {},"\
          " but RuntimeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with Regexp" do
      it "should not notify if an error with matching message is raised" do
        expect do
          :it.must_raise(/message/) { raise "some message" }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(/message/) {}
        should notify(":it.must_raise(/message/) {}, but nothing was raised")
      end
      
      it "should notify if an Exception with non-matching message"\
          " is raised" do
        expect do
          :it.must_raise(/message/) { raise "mess" }
        end.should raise_error
        should notify(":it.must_raise(/message/) {},"\
          " but RuntimeError with message \"mess\" was raised")
      end
    end
    
    context "when called with nil" do
      it "should not notify if any Exception is raised" do
        expect do
          :it.must_raise(nil) { raise Exception }
        end.should raise_error(Exception)
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(nil) {}
        should notify(":it.must_raise(nil) {}, but nothing was raised")
      end
    end
    
    context "when called with something other than an exception type,"\
        " nil, string, or regexp" do
      if RUBY_VERSION < "1.9"
        it "should raise TypeError without notifying" do
          expect do
            :it.must_raise(:not_an_error_type) { raise "havoc" }
          end.should raise_error(TypeError,
            "class or module required for rescue clause")
          should_not notify
        end
      else
        it "should notify" do
          expect do
            :it.must_raise(:not_an_error_type) { raise "havoc" }
          end.should raise_error(RuntimeError)
          should notify(":it.must_raise(:not_an_error_type) {},"\
            " but RuntimeError was raised")
        end
      end
    end
    
    context "when called with Exception type and String" do
      it "should not notify if an Exception of the same type with"\
          " the same message is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise TypeError, "oops" }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(TypeError, "oops") {}
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but nothing was raised")
      end
      
      it "should notify if an Exception of a different type is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise ArgumentError, "wrong" }
        end.should raise_error
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but ArgumentError was raised")
      end
      
      it "should notify if an Exception of the same type"\
          " but with a different message is raised" do
        expect do
          :it.must_raise(TypeError, "oops") { raise TypeError, "wrong" }
        end.should raise_error
        should notify(":it.must_raise(TypeError, \"oops\") {},"\
          " but TypeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with Exception type and Regexp" do
      it "should not notify if an Exception of the same type with"\
          " matching message is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise TypeError, "oops" }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(TypeError, /oops/) {}
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but nothing was raised")
      end
      
      it "should notify if an Exception of a different type is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise ArgumentError, "wrong" }
        end.should raise_error
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but ArgumentError was raised")
      end
      
      it "should notify if an Exception of the same type"\
          " but with a non-matching message is raised" do
        expect do
          :it.must_raise(TypeError, /oops/) { raise TypeError, "wrong" }
        end.should raise_error
        should notify(":it.must_raise(TypeError, /oops/) {},"\
          " but TypeError with message \"wrong\" was raised")
      end
    end
    
    context "when called with Exception type and nil" do
      it "should not notify if an Exception of the same type is raised" do
        expect do
          :it.must_raise(TypeError, nil) { raise TypeError }
        end.should raise_error
        should_not notify
      end
      
      it "should notify if no Exception is raised" do
        :it.must_raise(TypeError, nil) {}
        should notify(":it.must_raise(TypeError, nil) {},"\
          " but nothing was raised")
      end
      
      it "should notify if a different Exception type is raised" do
        expect do
          :it.must_raise(TypeError, nil) { raise ArgumentError }
        end.should raise_error
        should notify(":it.must_raise(TypeError, nil) {},"\
          " but ArgumentError was raised")
      end
    end
  end
  
  describe "#must_not_raise" do
    it_should_behave_like "*_raise in case of bad arguments"
    
    context "when called with no arguments" do
      it "should notify if any Exception is raised" do
        expect do
          :it.must_not_raise { raise Exception }
        end.should raise_error(Exception)
        should notify(":it.must_not_raise {}, but raised Exception")
      end
      
      it "should not notify if no Exception is raised" do
        called = false
        :it.must_not_raise {called = true; :result}.should == :result
        called.should be_true
        should_not notify
      end
    end
    
    context "when called with an Exception type" do
      it "should notify if an Exception of the same type is raised" do
        expect do
          :it.must_not_raise(TypeError) { raise TypeError }
        end.should raise_error
        should notify(":it.must_not_raise(TypeError) {},"\
          " but raised TypeError")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(TypeError) {}
        should_not notify
      end
      
      it "should not notify if a different Exception type is raised" do
        expect do
          :it.must_not_raise(TypeError) { raise ArgumentError }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with String" do
      it "should notify if an error with the same message is raised" do
        expect do
          :it.must_not_raise("message") { raise "message" }
        end.should raise_error
        should notify(":it.must_not_raise(\"message\") {},"\
          " but raised RuntimeError with message \"message\"")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise("message") {}
        should_not notify
      end
      
      it "should not notify if an Exception with a different message is"\
          " raised" do
        expect do
          :it.must_not_raise("message") { raise "wrong" }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with Regexp" do
      it "should notify if an error with matching message is raised" do
        expect do
          :it.must_not_raise(/message/) { raise "some message" }
        end.should raise_error
        should notify(":it.must_not_raise(/message/) {},"\
          " but raised RuntimeError with message \"some message\"")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(/message/) {}
        should_not notify
      end
      
      it "should not notify if an Exception with non-matching message"\
          " is raised" do
        expect do
          :it.must_not_raise(/message/) { raise "mess" }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with nil" do
      it "should notify if any Exception is raised" do
        expect do
          :it.must_not_raise(nil) { raise Exception }
        end.should raise_error(Exception)
        should notify(":it.must_not_raise(nil) {}, but raised Exception")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(nil) {}
        should_not notify
      end
    end
    
    context "when called with something other than an exception type,"\
        " nil, string, or regexp" do
      it "should not notify" do
        expect do
          :it.must_not_raise(:not_an_error_type) { raise "havoc" }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with Exception type and String" do
      it "should notify if an Exception of the same type with"\
          " the same message is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise TypeError, "oops" }
        end.should raise_error
        should notify(":it.must_not_raise(TypeError, \"oops\") {},"\
          " but raised TypeError with message \"oops\"")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(TypeError, "oops") {}
        should_not notify
      end
      
      it "should not notify if an Exception of a different type is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise ArgumentError, "grr" }
        end.should raise_error
        should_not notify
      end
      
      it "should not notify if an Exception of the same type"\
          " but with a different message is raised" do
        expect do
          :it.must_not_raise(TypeError, "oops") { raise TypeError, "wrong" }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with Exception type and Regexp" do
      it "should notify if an Exception of the same type with"\
          " matching message is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise TypeError, "oops" }
        end.should raise_error
        should notify(":it.must_not_raise(TypeError, /oops/) {},"\
          " but raised TypeError with message \"oops\"")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(TypeError, /oops/) {}
        should_not notify
      end
      
      it "should not notify if an Exception of a different type is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise ArgumentError, "grr" }
        end.should raise_error
        should_not notify
      end
      
      it "should not notify if an Exception of the same type"\
          " but with a non-matching message is raised" do
        expect do
          :it.must_not_raise(TypeError, /oops/) { raise TypeError, "wrong" }
        end.should raise_error
        should_not notify
      end
    end
    
    context "when called with Exception type and nil" do
      it "should notify if an Exception of the same type is raised" do
        expect do
          :it.must_not_raise(TypeError, nil) { raise TypeError }
        end.should raise_error
        should notify(":it.must_not_raise(TypeError, nil) {},"\
          " but raised TypeError")
      end
      
      it "should not notify if no Exception is raised" do
        :it.must_not_raise(TypeError, nil) {}
        should_not notify
      end
      
      it "should not notify if a different Exception type is raised" do
        expect do
          :it.must_not_raise(TypeError, nil) { raise ArgumentError }
        end.should raise_error
        should_not notify
      end
    end
  end
  
  #!! #must_throw, #must_not_throw
end