module Superhosting
  module Controller
    class Site
      NAME_FORMAT = /^((?!-)[А-Яа-яA-Za-z0-9-]{1,63}(?<!-)\.)+[А-Яа-яA-Za-z]{2,6}$/

      def adding_validation(name:)
        resp = self.name_validation(name: name)
        resp = self.not_existing_validation(name: name) if resp.net_status_ok?
        resp
      end

      def name_validation(name:)
        name !~ NAME_FORMAT ? { error: :input_error, code: :invalid_site_name, data: { name: name, regex: NAME_FORMAT } } : {}
      end

      def existing_validation(name:)
        self.index[name].nil? ? { error: :logical_error, code: :site_does_not_exists, data: { name: name } } : {}
      end

      def alias_existing_validation(name:, alias_name:)
        self.index[name][:mapper].aliases.include?(alias_name)
      end

      def not_existing_validation(name:)
        self.existing_validation(name: name).net_status_ok? ? { error: :logical_error, code: :site_exists, data: { name: name} } : {}
      end

      def available_validation(name:)
        if (resp = self.existing_validation(name: name)).net_status_ok?
          resp = (self.index[name][:state_mapper].value == 'up') ? {} : { error: :logical_error, code: :site_is_not_available, data: { name: name }  }
        end
        resp
      end
    end
  end
end