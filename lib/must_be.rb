$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require 'must_be/core'
require 'must_be/basic'
require 'must_be/must_and_must_not'
require 'must_be/containers'
require 'must_be/containers_registered_classes'

module MustBe
  VERSION = '0.0.5'
end