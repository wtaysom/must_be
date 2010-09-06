module MustBe  
  def must_raise(expected_exception_or_message = (no_arg0 = true; Exception),
      expected_message = (no_arg1 = true; nil), &block)
    args = []
    args << expected_exception_or_message unless no_arg0
    args << expected_message unless no_arg1
    
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
      yield
    rescue expected_exception => actual_exception
      is_okay = true
      case expected_message
      when Regexp
        is_okay = expected_message =~ actual_exception.message
      when String
        is_okay = expected_message == actual_exception.message
      end
      unless is_okay
        must_notify(self, __method__, args, block,
          ", but #{actual_exception.class} with"\
          " message #{actual_exception.message.inspect} was raised")
      end
      raise
    rescue Exception => actual_exception
      must_notify(self, __method__, args, block,
        ", but #{actual_exception.class} was raised")
      raise
    end
    must_notify(self, __method__, args, block, ", but nothing was raised")
  end
  
  def must_not_raise(
      expected_exception_or_message = (no_arg0 = true; Exception),
      expected_message = (no_arg1 = true; nil), &block)
    args = []
    args << expected_exception_or_message unless no_arg0
    args << expected_message unless no_arg1
    
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
      yield
    rescue expected_exception => actual_exception
      is_okay = false
      case expected_message
      when Regexp
        is_okay = expected_message !~ actual_exception.message
      when String
        is_okay = expected_message != actual_exception.message
      end
      unless is_okay
        must_notify(self, __method__, args, block,
          ", but raised #{actual_exception.class}"+(
            expected_message ?
              " with message #{actual_exception.message.inspect}" : ""))
      end
      raise
    rescue Exception => actual_exception
      raise
    end
  end
  
  #!! #must_throw, #must_not_throw
end