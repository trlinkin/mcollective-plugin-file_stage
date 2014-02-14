require 'pathname'

module MCollective
  module Validator
    class Absolute_file_pathValidator
      def self.validate(path)
        Validator.typecheck(src, :string)
        Validator.validate(src, :shellsafe)

        path = Pathname.new(src)
        raise "Cannot use relative paths" unless path.absolute?
        raise "Path must be a file" unless path.file?
      end
    end
  end
end
