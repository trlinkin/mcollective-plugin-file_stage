require 'uri'
require 'pathname'

module MCollective
  module Validator
    class Stageing_srcValidator
      def self.validate(src)
        Validator.typecheck(src, :string)
        Validator.validate(src, :shellsafe)

        begin
          uri = URI.parse(URI.escape(src))
        rescue => detail
          raise "Could not understand source #{source}: #{detail}", detail
        end

        if uri.scheme.nil?
          path = Pathname.new(src)
          raise "Local source file path must be absolute '#{path.to_path}" unless path.absolute?
        else
          raise "Cannot use relative URLs '#{source}'" unless uri.absolute?
          raise "Cannot use opaque URLs '#{source}'" unless uri.hierarchical?
          raise "Cannot use URLs of type '#{uri.scheme}' as source for fileserving" unless %w{http https ftp file}.include?(uri.scheme)
        end

      end
    end
  end
end
