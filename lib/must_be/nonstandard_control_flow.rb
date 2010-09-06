module MustBe

private

  def must_raise__body(method, args, &block)
    expected_exception_or_message = args[0]
    expected_message = args[1]
        
    case expected_exception_or_message
    when nil, String, Regexp
      expected_message = expected_exception_or_message
      expected_exception = Exception
    else
      expected_exception = expected_exception_or_message
      case expected_message
      when nil, String, Regexp
      else
        raise TypeError, "nil, string, or regexp required"
      end
    end
    
    begin
      result = yield
    rescue expected_exception => actual_exception
      
      is_match = case expected_message
      when Regexp
        expected_message =~ actual_exception.message
      when String
        expected_message == actual_exception.message
      else
          true
      end
      
      if is_match
        if method == :must_not_raise
          must_notify(self, :must_not_raise, args, block,
            ", but raised #{actual_exception.class}"+(
              expected_message ?
                " with message #{actual_exception.message.inspect}" : ""))
        end
      else
        if method == :must_raise
          must_notify(self, :must_raise, args, block,
            ", but #{actual_exception.class} with"\
            " message #{actual_exception.message.inspect} was raised")
        end
      end

      raise
    rescue Exception => actual_exception
      if method == :must_raise
        must_notify(self, :must_raise, args, block,
          ", but #{actual_exception.class} was raised")
      end
      raise
    end
    
    if method == :must_raise
      must_notify(self, :must_raise, args, block, ", but nothing was raised")
    end
    
    result
  end

public
  
  def must_raise(*args, &block)
    must_raise__body(:must_raise, args, &block)
  end
  
  def must_not_raise(*args, &block)
    must_raise__body(:must_not_raise, args, &block)
  end
  
  #!! #must_throw, #must_not_throw
end