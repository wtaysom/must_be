### MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT ###
#
# Hard to describe within normal RSpec control flow.  Instead we raise a
# RuntimeError if MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT doesn't
# behave as expected.
#

ENV['MUST_BE__NOTIFIER'] = nil # to make `rake spec` work.
ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT'] = "" # any string.

require './lib/must_be'

if Object.include? MustBe
  raise "MustBe should not be automatically included in Object."
end

def expect_error(error_type)
  begin
    raised_error = false
    yield
  rescue error_type
    raised_error = true
  end
  raise "expected #{error_type}" unless raised_error
end

# Show that MustBe does not need to be included in Object to be useful.
def example_of_must_be_inclusion
  example = Object.new
  example.extend(MustBe)
  example.must == example
  example.must_not_be_nil

  # must_only_contain and must_not_contain require contents to also include
  # MustBe.
  contents = Object.new

  container = [contents]
  container.extend(MustBe)

  expect_error(NoMethodError) do
    container.must_only_contain
  end

  contents.extend(MustBe)
  expect_error(MustBe::Note) do
    container.must_not_contain
  end
end
example_of_must_be_inclusion

class Object
  include MustBe
end

### MustBeExampleHelper ###

module MustBeExampleHelper
  
  $default_must_be_notifier = MustBe.notifier
  
  def self.included(example_group)
    example_group.before do
      MustBe.notifier = lambda do |note|
        @note = note
        false
      end
    end

    class <<example_group
      
      ### Value Assertion ###
      
      def it_should_have_must_be_value_assertion(method, value, alt = 411)
        describe '##{method}' do
          it "should not notify if receiver is #{value.inspect}" do
            value.send(method).should == value
            should_not notify
          end

          it "should notify if receiver is not #{value.inspect}" do
            alt.send(method).should == alt
            should notify("#{alt.inspect}.#{method}")
          end
        end
      end

      def it_should_have_must_not_be_value_assertion(method, value, alt = 411)
        describe '##{method}' do
          it "should notify if receiver is #{value.inspect}" do
            value.send(method)
            should notify("#{value.inspect}.#{method}")
          end

          it "should not notify if receiver is not #{value.inspect}" do
            alt.send(method)
            should_not notify
          end
        end
      end
    
      ### Notify Example ###

      def notify_example(expression, message = nil)
        expression = expression.gsub(/\n\s*/, " ")
        if message.is_a? Module
          message = expression+", but matches #{message}"
        end
        example "#{expression} should #{message ? "" : "not "}notify" do
          eval(expression)
          if message == true
            should notify
          elsif message
            should notify(message)
          else
            should_not notify
          end
        end
      end
      
      ### Enable ###
      
      def before_disable_after_enable
        before do
          MustBe.disable
        end
        
        after do
          MustBe.enable
        end
      end
      
      def before_disable_and_reenable
        before do
         MustBe.disable
         MustBe.enable
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
            if message === @note.message
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