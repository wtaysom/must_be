here = File.expand_path(File.dirname(__FILE__))

if RUBY_VERSION < "1.8.7"
  unless :symbol.respond_to? :to_proc
    class Symbol
      def to_proc
        Proc.new {|*args| args.shift.__send__ self, *args}
      end
    end
  end
  
  unless "string".respond_to? :bytesize
    class String
      alias bytesize size
    end
  end
  
  unless [].respond_to? :none?
    class Array
      def none?(&block)
        not any?(&block)
      end
    end
  end
  
  unless [].respond_to? :drop_while
    class Array
      def drop_while 
        index = 0
        index += 1 while yield(self[index])
        self[index..-1]
      end
    end
  end
  
  unless 3.respond_to? :odd?
    class Integer
      def odd?
        self % 2 == 1
      end
    end
  end
  
  unless 3.respond_to? :even?
    class Integer
      def even?
        self % 2 == 0
      end
    end
  end
end

require here+'/must_be/core'
require here+'/must_be/basic'
require here+'/must_be/proxy'
require here+'/must_be/containers'
require here+'/must_be/containers_registered_classes'
require here+'/must_be/attr_typed'
require here+'/must_be/nonstandard_control_flow'