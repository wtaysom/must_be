module MustBe
  def self.match_any_case?(v, cases)
    cases = [cases] unless cases.is_a? Array
    cases.any? {|c| c === v }
  end
  
  def must_be(*cases)
    unless cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, __method__, cases, nil, ", but is #{self.class}")
    end
    self
  end

  def must_not_be(*cases)
    if cases.empty? ? self : MustBe.match_any_case?(self, cases)
      must_notify(self, __method__, cases, nil, ", but is #{self.class}")
    end
    self
  end
  
private

  def must_be_a__body(modules, test_method, method)
    if modules.size.zero?
      raise ArgumentError, "wrong number of arguments (0 for 1)"
    end
    ms = modules.last.is_a?(Module) ? modules : modules[0..-2]
    if ms.size.zero?
      raise TypeError, "class or module required"
    end
    ms.each do |mod|
      raise TypeError, "class or module required" unless mod.is_a? Module
    end
        
    if ms.send(test_method) {|mod| is_a? mod }
      must_notify(self, method, modules, nil, ", but is a #{self.class}")
    end
    self
  end

public
  
  def must_be_a(*modules)
    must_be_a__body(modules, :none?, __method__)
  end
  
  def must_not_be_a(*modules)
    must_be_a__body(modules, :all?, __method__)
  end
  
  def must_be_in(*collection)
    cs = collection.size == 1 ? collection[0] : collection
    unless cs.include? self
      must_notify(self, __method__, collection)
    end
    self
  end
  
  def must_not_be_in(*collection)
    cs = collection.size == 1 ? collection[0] : collection
    if cs.include? self
      must_notify(self, __method__, collection)
    end
    self
  end
  
  def must_be_nil
    must_notify(self, __method__) unless nil?
    self
  end
  
  def must_not_be_nil
    must_notify(self, __method__) if nil?
    self
  end
  
  def must_be_true
    must_notify(self, __method__) unless self == true
    self
  end
  
  def must_be_false
    must_notify(self, __method__) unless self == false
    self
  end
  
  def must_be_boolean
    unless self == true or self == false
      must_notify(self, __method__)
    end
    self
  end
  
  def must_be_close(expected, delta = 0.1)
    unless (self - expected).abs < delta
      must_notify(self, __method__, [expected, delta])
    end
    self
  end
  
  def must_not_be_close(expected, delta = 0.1)
    if (self - expected).abs < delta
      must_notify(self, __method__, [expected, delta])
    end
    self
  end
  
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

### Proc Case Equality Patch ###
#
# Semantics of case equality `===' for Proc changed between Ruby 1.8 (useless)
# and Ruby 1.9 (awesome).  So let's fix 'er up.
#
if RUBY_VERSION < "1.9"
  class Proc
    alias === call
  end
end