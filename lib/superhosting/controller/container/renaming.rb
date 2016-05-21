module Superhosting
  module Controller
    class Container
      def copy_etc(name:, new_name:)
        mapper = index[name].mapper
        new_etc_mapper = mapper.etc.parent.f(new_name)
        mapper.rename!(new_etc_mapper.path)
        mapper.create!

        {}
      end

      def undo_copy_etc(name:, new_name:)
        mapper = index[name].mapper
        new_etc_mapper = mapper.etc.parent.f(new_name)
        new_etc_mapper.rename!(mapper.path)
        new_etc_mapper.delete!

        {}
      end

      def copy_var(name:, new_name:)
        mapper = index[name].mapper
        new_mapper = index[new_name].mapper
        mapper.lib.web.rename!(new_mapper.lib.web.path)
        mapper.lib.sites.rename!(new_mapper.lib.sites.path)
        mapper.lib.registry.sites.rename!(new_mapper.lib.registry.sites.path)

        if has_sites?(name: name)
          site_controller = controller(Site)
          site_controller.reindex_container_sites(container_name: new_name)
          site_controller.reindex_container_sites(container_name: name)
        end

        {}
      end

      def undo_copy_var(name:, new_name:)
        mapper = index[name].mapper
        new_mapper = index[new_name].mapper

        unless new_mapper.nil?
          new_mapper.lib.web.safe_rename!(mapper.lib.web.path)
          new_mapper.lib.sites.safe_rename!(mapper.lib.sites.path)
          new_mapper.lib.registry.sites.safe_rename!(mapper.lib.registry.sites.path)
        end

        if has_sites?(name: name)
          site_controller = controller(Site)
          site_controller.reindex_container_sites(container_name: name)
          site_controller.reindex_container_sites(container_name: new_name)
        end

        {}
      end

      def copy_users(name:, new_name:)
        mapper = index[name].mapper
        user_controller = controller(User)
        container_admin_controller = admin(name: new_name)

        mapper.config.f('etc-passwd').lines.each do |line|
          parts = line.split(':')
          user_name = parts.first
          shell = parts.pop
          home_dir = parts.pop
          next if user_name == name || # base_user
                  line.start_with?('root')

          if user_controller.admin?(name: user_name, container_name: name)
            _name, admin_name = user_name.split('_admin_')
            container_admin_controller.add(name: admin_name).net_status_ok!
          else
            cuser_name = user_name[/(?<=#{name}_)(.*)/]
            if user_controller.system?(name: cuser_name, container_name: name)
              user_controller._add_system_user(name: cuser_name, container_name: new_name)
            else
              user_controller._add(name: cuser_name, container_name: new_name, shell: shell, home_dir: home_dir)
            end
          end
        end

        {}
      end

      def move_databases(name:, new_name:)
        mysql_controller = controller(Mysql)
        mysql_controller._move(container_name: name, new_container_name: new_name)

        {}
      end

      def undo_move_databases(name:, new_name:)
        mysql_controller = controller(Mysql)
        mysql_controller._move(container_name: new_name, new_container_name: name)

        {}
      end

      def new_up(new_name:, model:)
        _reconfigure(name: new_name, model: model)
      end

      def undo_new_up(new_name:)
        delete(name: new_name)
      end

      def new_reconfigure(new_name:)
        reconfigure(name: new_name)
      end

      def undo_new_reconfigure(new_name:)
        unconfigure_with_unapply(name: new_name)
      end
    end
  end
end
