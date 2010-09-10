require 'forwardable'

module MustBe
  class ContainerNote < Note
    extend Forwardable
    
    attr_accessor :original_note, :container
    
    def_delegators :@original_note,
      :receiver, :receiver=,
      :assertion, :assertion=,
      :args, :args=,
      :block, :block=,
      :additional_message, :additional_message=,
      :prefix, :prefix=
    
    def initialize(original_note, container = nil)
      @original_note = original_note
      @container = container
    end
    
    def to_s
      if assertion
        super+" in container #{MustBe.short_inspect(container)}"
      else
        super
      end
    end
    
    alias regular_backtrace backtrace
    
    def backtrace
      return unless regular_backtrace
      
      if container.respond_to?(:must_only_ever_contain_backtrace) and
          container.must_only_ever_contain_backtrace
        regular_backtrace+["=== caused by container ==="]+
          container.must_only_ever_contain_backtrace
      else
        regular_backtrace
      end
    end
  end
  
  class PairNote < ContainerNote
    attr_accessor :key, :value, :cases, :negate
    
    def initialize(key, value, cases, container, negate)
      super(Note.new(""), container)
      @key = key
      @value = value
      @cases = cases
      @negate = negate
    end
    
    def to_s
      match = negate ? "matches" : "does not match"
      "#{prefix}pair {#{MustBe.short_inspect(key)}=>"\
        "#{MustBe.short_inspect(value)}} #{match}"\
        " #{MustBe.short_inspect(cases)} in"\
        " container #{MustBe.short_inspect(container)}"
    end
  end

  def self.check_pair_against_hash_cases(key, value, cases, negate = false)
    if negate
      if cases.empty?
        !key and !value
      else
        cases.all? do |c|
          c.all? do |k, v|
            not (match_any_case?(key, k) and match_any_case?(value, v))
          end
        end
      end
    else
      if cases.empty?
        key and value
      else
        cases.any? do |c|
          c.any? do |k, v|
            match_any_case?(key, k) and match_any_case?(value, v)
          end
        end
      end
    end
  end
  
  def self.must_check_member_against_cases(container, member, cases, negate = false)
    member.must_check(lambda do
      if negate
        member.must_not_be(*cases)
      else
        member.must_be(*cases)
      end
    end) do |note|
      note = ContainerNote.new(note, container)
      block_given? ? yield(note) : note
    end
  end

  def self.must_check_pair_against_hash_cases(container, key, value, cases,
      negate = false)
    unless MustBe.check_pair_against_hash_cases(key, value, cases, negate)
      note = PairNote.new(key, value, cases, container, negate)
      must_notify(block_given? ? yield(note) : note)
    end
  end
  
  def self.must_only_contain(container, cases, negate = false)
    prefix = negate ? "must_not_contain: " : "must_only_contain: "
    
    advice = MustOnlyEverContain.registered_class(container)    
    if advice and advice.respond_to? :must_only_contain_check
      advice.must_only_contain_check(container, cases, negate)
    elsif container.respond_to? :each_pair
      container.each_pair do |key, value|
        MustBe.must_check_pair_against_hash_cases(container, key, value,
            cases, negate) do |note|
          note.prefix = prefix
          note
        end
      end
    else
      container.each do |member|
        MustBe.must_check_member_against_cases(container, member, cases,
            negate) do |note|
          note.prefix = prefix
          note
        end
      end
    end
    container
  end

  def must_only_contain(*cases)
    MustBe.must_only_contain(self, cases)
  end
  
  def must_not_contain(*cases)
    MustBe.must_only_contain(self, cases, true)
  end
  
  module MustOnlyEverContain
    REGISTERED_CLASSES = {}
    
    module Base
      attr_accessor :must_only_ever_contain_cases, 
        :must_only_ever_contain_backtrace, :must_only_ever_contain_negate
      
      module ClassMethods
        def must_check_contents_after(*methods)
          methods.each do |method|
            define_method(method) do |*args, &block|
              begin
                super(*args, &block)
              ensure
                must_check_contents
              end
            end
          end
        end
      end
      
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      def must_only_ever_contain_prefix
        must_only_ever_contain_negate ? "must_never_ever_contain: " : 
          "must_only_ever_contain: "
      end

      def must_only_ever_contain_cases=(cases)
        cases = [cases] unless cases.is_a? Array
        @must_only_ever_contain_cases = cases
        
        must_check(lambda { must_check_contents }) do |note|
          note.prefix = must_only_ever_contain_prefix
          note
        end
      end
      
    protected
    
      def must_check_member(member)
        MustBe.must_check_member_against_cases(self, member, 
          must_only_ever_contain_cases, must_only_ever_contain_negate)
      end
      
      def must_check_pair(key, value)
        MustBe.must_check_pair_against_hash_cases(self, key, value, 
          must_only_ever_contain_cases, must_only_ever_contain_negate)
      end
      
      def must_check_contents(members = self)
        MustBe.must_only_contain(members, must_only_ever_contain_cases,
          must_only_ever_contain_negate)
      end
    end
    
  public
    
    ##
    # Creates a module from `body' which includes MustOnlyEverContain::Base.
    # The module will be mixed into an objects of type `klass' when
    # `must_only_ever_contain' is called.  The module should override methods of
    # `klass' which modify the contents of the object.
    # If the module has a class method
    # `must_only_contain_check(object, cases, negate = false)',
    # then this method is used by `MustBe.must_only_contain'
    # to check the contents of `object' against `cases'.
    # `must_only_contain_check' should call `MustBe#must_notify' for any
    # contents which do not match `cases'.  (Or if `negate' is true, then
    # `MustBe#must_notify' should be called for any contents that do match
    # `cases'.)
    #
    def self.register(klass, &body)
      unless klass.is_a? Class
        raise ArgumentError, "invalid value for Class: #{klass.inspect}"
      end
      if REGISTERED_CLASSES[klass]
        raise ArgumentError, "handler for #{klass} previously provided"
      end
      
      REGISTERED_CLASSES[klass] = mod = Module.new
      mod.send(:include, Base)
      mod.class_eval &body
      
      mutator_advice = Module.new
      mod.instance_methods(false).each do |method_name|
        mutator_advice.send(:define_method, method_name) do |*args, &block|
          must_check(lambda { super(*args, &block) }) do |note|
            note.prefix = nil
            call_s = Note.new(self.class, method_name, args, block).message
            call_s.sub!(".", "#")
            note.prefix = "#{must_only_ever_contain_prefix}#{call_s}\n"
            note
          end
        end
      end
      mod.const_set(:MutatorAdvice, mutator_advice)
      mod.instance_eval do
        def extended(base)
          base.extend(const_get(:MutatorAdvice))
        end
      end
      
      mod
    end
    
    def self.registered_class(object)
      REGISTERED_CLASSES[object.class]
    end
    
    def self.unregister(klass)
      REGISTERED_CLASSES.delete(klass)
    end
  end
  
  def self.must_only_ever_contain(container, cases, negate = false)
    unless container.singleton_methods.empty?
      method_name = "must_#{negate ? "never" : "only"}_ever_contain"
      raise ArgumentError, "#{method_name} adds singleton methods but"\
        " receiver #{MustBe.short_inspect(container)} already"\
        " has singleton methods #{container.singleton_methods.inspect}"
    end
    
    advice = MustOnlyEverContain.registered_class(container)
    if advice
      container.extend advice
      container.must_only_ever_contain_backtrace = caller
      container.must_only_ever_contain_negate = negate
      container.must_only_ever_contain_cases = cases
    else
      raise TypeError,
        "No MustOnlyEverContain.registered_class for #{container.class}"
    end
    container
  end
  
  def must_only_ever_contain(*cases)
    MustBe.must_only_ever_contain(self, cases)
  end
  
  def must_never_ever_contain(*cases)
    MustBe.must_only_ever_contain(self, cases, true)
  end
end