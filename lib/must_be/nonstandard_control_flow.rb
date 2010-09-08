module MustBe

private

  def must_raise__body(method, args, &block)
    if args.size > 2
      raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
    elsif args.size == 2
      expected_exception = args[0]
      expected_message = args[1]
    else
      case args[0]
      when nil, String, Regexp
        expected_exception = Exception
        expected_message = args[0]
      else
        expected_exception = args[0]
      end
    end
    
    unless expected_exception.is_a?(Class) and
        expected_exception.ancestors.include?(Exception)
      raise TypeError, "exception class expected"
    end
    
    case expected_message
    when nil, String, Regexp
    else
      raise TypeError, "nil, string, or regexp required"
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
  
  register_disabled_method(:must_raise, :must_just_yield)
  register_disabled_method(:must_not_raise, :must_just_yield)

private
  
  @@must_throw__installed = false
  
  def must_throw__body(method, args, &block)
    if args.size > 2
      raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
    end
    tag = args[0]
    obj = args[1]
    
    unless @@must_throw__installed
      original_throw = Kernel.instance_method(:throw)
      Kernel.send(:define_method, :throw) do |*args|
        Thread.current[:must_throw__args] = args
        original_throw.bind(self)[*args]
      end
      @@must_throw__installed = true
    end
    
    begin
      raised = false
      returned_normaly = false
      result = yield
      returned_normaly = true    
      result
    rescue Exception => ex
      if method == :must_throw
        must_notify(self, :must_throw, args, block,
          ", but raised #{ex.class}")
      end
      raised = true
      raise
    ensure
      if raised
      elsif returned_normaly
        if method == :must_throw
          must_notify(self, :must_throw, args, block, ", but did not throw")
        end
      else
        thrown = Thread.current[:must_throw__args]
        thrown_tag = thrown[0]
        thrown_obj = thrown[1]
        
        if method == :must_throw
          if args.size >= 1 and tag != thrown_tag
            must_notify(self, :must_throw, args, block,
              ", but threw #{thrown.map(&:inspect).join(", ")}")
          elsif args.size == 2 and thrown.size < 2 || obj != thrown_obj
            must_notify(self, :must_throw, args, block,
              ", but threw #{thrown.map(&:inspect).join(", ")}")
          end
        elsif method == :must_not_throw
          if args.size == 0 or args.size == 1 && tag == thrown_tag or
              args.size == 2 && tag == thrown_tag && thrown.size == 2 &&
                obj == thrown_obj
            must_notify(self, :must_not_throw, args, block,
              ", but threw #{thrown.map(&:inspect).join(", ")}")
          end
        end
      end
    end
  end

public
  
  def must_throw(*args, &block)
    must_throw__body(:must_throw, args, &block)
  end
  
  def must_not_throw(*args, &block)
    must_throw__body(:must_not_throw, args, &block)
  end
  
  register_disabled_method(:must_throw, :must_just_yield)
  register_disabled_method(:must_not_throw, :must_just_yield)
end