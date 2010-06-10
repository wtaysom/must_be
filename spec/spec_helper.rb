require 'lib/must_be'

module MustBeExampleHelper

  def self.included(example_group)
    example_group.before do
      MustBe.notifier = lambda do |note|
        @note = note
        false
      end
    end

### Value Assertion ###

    class <<example_group      
      def it_should_have_must_be_value_assertion(method, value, alt = 411)
        describe "##{method}" do
          it "should not notify if sender is #{value.inspect}" do
            value.send(method).should == value
            should_not notify
          end

          it "should notify if sender is not #{value.inspect}" do
            alt.send(method).should == alt
            should notify("#{alt.inspect}.#{method}")
          end
        end
      end

      def it_should_have_must_not_be_value_assertion(method, value, alt = 411)
        describe "##{method}" do
          it "should notify if sender is #{value.inspect}" do
            value.send(method)
            should notify("#{value.inspect}.#{method}")
          end

          it "should not notify if sender is not #{value.inspect}" do
            alt.send(method)
            should_not notify
          end
        end
      end
    end
  end
  
### Notify Matcher ###
  
  def notify(message = nil)
    simple_matcher do |given, matcher|
      result, message =
        if @note
          if message
            if message == @note.message
              [true,
                "did NOT expect note with message: #{message.inspect}\n"\
                "           got note with message: #{@note.message.inspect}"]
            else
              [false,
                "expected note with message: #{message.inspect}\n"\
                "     got note with message: #{@note.message.inspect}"]
            end
          else
            [true,
              "expected no note\n"\
              "got note with message: #{@note.message.inspect}"]
          end
        else
          [false, if message
            "expected a note with message: #{message.inspect}"
          else
            "expected a note"
          end]
        end
    
      if result
        matcher.negative_failure_message = message
      else
        matcher.failure_message = message
      end
    
      result
    end
  end
end