require 'pathname'

module MCollective
  module Validator
    class Absolute_file_pathValidator
      def self.validate(raw_path)
        Validator.typecheck(raw_path, :string)
        Validator.validate(raw_path, :shellsafe)

        path = Pathname.new(raw_path)
        raise "Cannot use relative paths" unless path.absolute?
        raise "Path must be a file" unless path.file?
      end
    end
  end
end
