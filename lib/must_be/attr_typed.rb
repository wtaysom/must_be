class Module
  def attr_typed(symbol, *types, &test)
    raise TypeError, "#{symbol} is not a symbol" if symbol.is_a? Integer
    
    types.each do |type|
      raise TypeError, "class or module required" unless type.is_a? Module
    end
    
    attr_reader symbol
    name = symbol.to_sym.id2name
    check_method_name = "attr_typed__check_#{name}"
    
    unless types.empty?
      types_message = types.size == 1 ? types[0] :
        types.size == 2 ? "#{types[0]} or #{types[1]}" :
        "one of #{types.inspect}"
            
      type_check = lambda do |value|
        if types.none?{|type| value.is_a? type }
          must_notify("attribute `#{name}' must be a #{types_message},"\
            " but value #{value.inspect} is a #{value.class}")
        end
      end
    end
    
    if test
      test_check = lambda do |value|
        unless test[value]
          must_notify("attribute `#{name}' cannot be #{value.inspect}")
        end
      end
    end
    
    define_method(check_method_name, &(
      if types.empty?
        if test
          test_check
        else
          lambda do |value|
            if value.nil?
              must_notify("attribute `#{name}' cannot be nil")
            end
          end
        end
      else
        if test
          lambda do |value|
            type_check[value]
            test_check[value]
          end
        else
          type_check
        end
      end
    ))
    
    module_eval(<<-END, __FILE__, __LINE__ + 1)
      def #{name}=(value)
        #{check_method_name}(value)
        @#{name} = value
      end
    END
  end
  
  MustBe.register_disabled_handler do |enabled|
    if enabled
      if method(:attr_typed__original)
        alias attr_typed attr_typed__original
        remove_method(:attr_typed__original)
      end
    else
      alias attr_typed__original attr_typed
      define_method(:attr_typed) do |symbol, *types|
        attr_accessor symbol
      end
    end
  end
end