module MustBe
  VERSION = '0.0.1'
  
  class <<self
    attr_accessor :notifier # should respond_to? :call with Note argument.
    
### Enable ###
        
    def disable
      @disabled_methods = instance_methods.map do |method_name|
        method = instance_method(method_name)
        alias_method method_name, :must_just_return
        [method_name, method]
      end
    end
    
    def enable
      @disabled_methods.each do |method_record|
        define_method *method_record
      end
      @disabled_methods = nil
    end
    
    def enable?
      @disabled_methods.nil?
    end
  end
  
  self.notifier = RaiseNotifier = lambda {|note| true }
  
  def must_just_return(*args)
    self
  end
  
### Note ###
  
  class Note < StandardError
    attr_accessor :receiver, :assertion, :args, :block
    
    def initialize(receiver, assertion = nil, args = nil, block = nil)
      if assertion
        @receiver = receiver
        @assertion = assertion
        @args = args
        @block = block
      else
        super(receiver)
      end
    end
    
    def to_s
      if @assertion
        "#{receiver.inspect}.#{assertion}#{format_args_and_block}"
      else
        super
      end
    end
        
    alias complete_backtrace backtrace
    
    def backtrace
      complete_backtrace and complete_backtrace.drop_while do |line|
        line =~ %r{lib/must_be\.rb:}
      end
    end
  
  private
    
    def format_args_and_block
      if args.nil? or args.empty?
        if block.nil?
          ""
        else
          " {}"
        end
      else
        args_format = "(#{args.map(&:inspect).join(", ")})"
        if block.nil?
          args_format
        else
          args_format+" {}"
        end
      end
    end
  end
  
  def must_notify(receiver = nil, assertion= nil, args = nil, block = nil)
    note = Note === receiver ? receiver :
      Note.new(receiver, assertion, args, block)
    if $must_check__is_checking
      $must_check__found = note
    else
      raise note if MustBe.notifier.call(note)
    end
    note
  end
  
  def must_check
    #! use thread-local variables
    was_checking = $must_check__is_checking
    $must_check__is_checking = true
    
    already_found = $must_check__found
    $must_check__found = nil
    
    yield(self)
    
    $must_check__found
  ensure
    $must_check__is_checking = was_checking
    $must_check__found = already_found
  end

### Basic Assertions ###
  
  def must_be(*cases)
    if cases.empty? ? !self : cases.none? {|c| c === self }
      must_notify(self, __method__, cases)
    end
    self
  end

  def must_not_be(*cases)
    unless cases.empty? ? !self : cases.none? {|c| c === self }
      must_notify(self, __method__, cases)
    end
    self 
  end
  
  def must_be_in(collection)
    unless collection.include? self
      must_notify(self, __method__, [collection])
    end
    self
  end
  
  def must_not_be_in(collection)
    if collection.include? self
      must_notify(self, __method__, [collection])
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
  
### must and must_not ###
  
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
      unless yield(self, message)
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
  
  #!! should take &block -- need an example showing this
  def must_not(message = nil)
    if block_given?
      if yield(self, message)
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

### Containers ###

  def self.check_pair_against_hash_cases(key, value, cases)
    cases.empty? ? key && value : cases.any? do |c|
      not c.each_pair do |k, v|
        if k === key and v === value
          break
        end
      end
    end
  end

  def must_only_contain(*cases)
    if respond_to? :each_pair
      each_pair do |key, value|
        unless MustBe.check_pair_against_hash_cases(key, value, cases)
          #! better message
          must_notify("pair #{{key => value}.inspect} does not match "\
            "#{cases.inspect} in #{inspect}")
        end
      end
    else
      each do |item|
        #! better message -- use `must_check' then
        # may want to customize Note to make it easier to build that custom
        # message
        item.must_be(*cases)
      end
    end
    self
  end
  
  #! should raise when there are already singleton methods defined on self
  #! spec that the installation depends on the class
  #! be able to register new classes (e.g. Set)
  def must_only_ever_contain(*cases)
    must_only_contain(cases)
    
    if instance_of? Hash
      #!! why not just include a module?
      class <<self
        attr_accessor :must_only_ever_contain_cases
        
        def must_only_ever_contain_cases=(cases)
          @must_only_ever_contain_cases = cases
          must_only_contain(cases)
        end
        
        def []=(key, value)
          unless MustBe.check_pair_against_hash_cases(key, value,
              must_only_ever_contain_cases)
            #! better message
            must_notify("pair #{{key => value}.inspect} does not match "\
              "#{must_only_ever_contain_cases.inspect} in #{inspect}")
          end
          super
        end
      end
      self.must_only_ever_contain_cases = cases
    elsif instance_of? Array
      #!! array case: lots of methods to override to be useful
      raise "Array receiver unimplemented"
    else
      #!! complain
      raise "decide on the right error to raise: TypeError?"
    end
    self
  end
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

### Automatically Inclue in Object ###

unless ENV["MUST_BE__SHOULD_NOT_AUTOMATICALLY_BE_INCLUDED_IN_OBJECT"]
  class Object
    include MustBe
  end
end