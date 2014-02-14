require 'uri'
require 'pathname'

module MCollective
  module Validator
    class Stage_srcValidator
      def self.validate(src)
        Validator.typecheck(src, :string)
        Validator.validate(src, :shellsafe)

        path = Pathname.new(src)
        unless path.file? and path.absolute?
          begin
            uri = URI.parse(URI.escape(src))
          rescue => detail
            raise "Could not understand source #{source}: #{detail}", detail
          end
          uri = URI.parse(URI.escape(src))
          raise "Cannot use relative URLs '#{source}'" unless uri.absolute?
          raise "Cannot use opaque URLs '#{source}'" unless uri.hierarchical?
          raise "Cannot use URLs of type '#{uri.scheme}' as source for fileserving" unless %w{http https ftp}.include?(uri.scheme)
        end
      end
    end
  end
end
