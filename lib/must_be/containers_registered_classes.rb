module MustBe::MustOnlyEverContain
  
  ### Array ###
  
  register Array do
    must_check_contents_after :collect!, :map!, :flatten!
    
    def <<(obj)
      must_check_item(obj)
      super
    end
    
    def []=(*args)
      if args.size == 3 or args[0].is_a? Range
        value = args.last
        if value.nil?
          # No check needed.
        elsif value.is_a? Array
          value.map {|v| must_check_item(v) }
        else
          must_check_item(value)
        end
      else
        must_check_item(args[1])
      end
      super
    end
    
    def concat(other_array)
      must_check_contents(other_array)
      super
    end
    
    def fill(*args)
      if block_given?
        begin
          super
        ensure
          must_check_contents
        end
      else
        must_check_item(args[0])
        super
      end
    end
    
    def insert(index, *objs)
      must_check_contents(objs)
      super
    end
    
    def push(*objs)
      must_check_contents(objs)
      super
    end
    
    def replace(other_array)
      must_check_contents(other_array)
      super
    end
    
    def unshift(*objs)
      must_check_contents(objs)
      super
    end
  end
  
  ### Hash ###
  
  register Hash do
    must_check_contents_after :replace, :merge!, :update
    
    def []=(key, value)
      must_check_pair(key, value)
      super
    end
          
    def store(key, value)
      must_check_pair(key, value)
      super
    end
  end
end