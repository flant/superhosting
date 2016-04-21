module Superhosting
  module CompositeMapper
    extend Helper::Mapper

    def self.new(etc_mapper:, lib_mapper:, web_mapper:)
      klass = case type = mapper_type(etc_mapper)
        when 'container' then Container
        when 'site' then Site
        else raise NetStatus::Exception, error: :logical_error, code: :mapper_type_not_supported, data: { name: type }
      end
      klass.new(etc_mapper: etc_mapper, lib_mapper: lib_mapper, web_mapper: web_mapper)
    end
  end
end
