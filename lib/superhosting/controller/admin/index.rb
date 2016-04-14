module Superhosting
  module Controller
    class Admin
      def initialize(**kwargs)
        super(**kwargs)
        @admins_mapper = @config.admins
        self.index
      end

      def index
        @@index ||= self.reindex
      end

      def reindex
        @@index = {}
        @admins_mapper.grep_dirs.each {|dir_name| self.reindex_admin(name: dir_name.name) }
        @@index
      end

      def reindex_admin(name:)
        @@index ||= {}
        if @admins_mapper.f(name).nil?
          @@index.delete(name)
        else
          admin_container_controller = self.get_controller(Admin::Container, name: name)
          @@index[name] = admin_container_controller._users_list.net_status_ok![:data] || []
        end
      end
    end
  end
end