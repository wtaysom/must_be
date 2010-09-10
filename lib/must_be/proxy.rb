module MustBe
  class Proxy
    mandatory_methods = [:__id__, :object_id, :__send__]
    
    if RUBY_VERSION < "1.9"
      mandatory_methods.map! &:to_s
    end
    
    (instance_methods - mandatory_methods).each do |method|
      undef_method(method)
    end
    
    def initialize(delegate, assertion = :must)
      unless assertion == :must or assertion == :must_not
        raise ArgumentError,
          "assertion (#{assertion.inspect}) must be :must or :must_not"
      end
      @delegate = delegate
      @assertion = assertion
    end
    
    def method_missing(symbol, *args, &block)
      result = @delegate.send(symbol, *args, &block)
      assertion = result ? true : false
      unless assertion == (@assertion == :must)
        @delegate.must_notify(@delegate, "#{@assertion}.#{symbol}", args, 
          block)
      end
      result
    end
  end
  
  def must(message = nil, &block)
    if block_given?
      unless block.arity > 1 ? yield(self, message) : yield(self)
        if message
          must_notify(message)
        else
          must_notify(self, __method__, nil, block)
        end
      end
      self
    else
      Proxy.new(self, :must)
    end
  end
  
  def must_not(message = nil, &block)
    if block_given?
      if block.arity > 1 ? yield(self, message) : yield(self)
        if message
          must_notify(message)
        else
          must_notify(self, __method__, nil, block)
        end
      end
      self
    else
      Proxy.new(self, :must_not)
    end
  end
end