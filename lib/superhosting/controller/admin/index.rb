module Superhosting
  module Controller
    class Admin
      class << self; attr_accessor :index end

      def initialize(**kwargs)
        super(**kwargs)
        @admins_mapper = @lib.admins
        index
      end

      def index
        self.class.index ||=  with_profile('admin_index') { reindex }
      end

      def reindex
        self.class.index = {}
        @admins_mapper.grep_dirs.each { |dir_name| reindex_admin(name: dir_name.name) }
        self.class.index
      end

      def reindex_admin(name:)
        self.class.index ||= {}
        if @admins_mapper.f(name).nil?
          self.class.index.delete(name)
        else
          admin_container_controller = controller(Admin::Container, name: name)
          self.class.index[name] = admin_container_controller._users_list || []
        end
      end
    end
  end
end
