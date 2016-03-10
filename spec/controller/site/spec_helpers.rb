module SpecHelpers
  module Controller
    module Site
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def site_controller
        @site_controller ||= Superhosting::Controller::Site.new
      end

      # methods

      def site_add(**kwargs)
        site_controller.add(**kwargs)
      end

      def site_delete(**kwargs)
        site_controller.delete(**kwargs)
      end

      def site_rename(**kwargs)
        site_controller.rename(**kwargs)
      end

      def site_alias_add(**kwargs)
        site_controller.alias(name: @site_name).add(**kwargs)
      end

      def site_alias_delete(**kwargs)
        site_controller.alias(name: @site_name).delete(**kwargs)
      end

      # expectations

      def site_add_exps(**kwargs)
        config_mapper = site_controller.config
        lib_mapper = site_controller.lib
        container_name = kwargs[:container_name] || @container_name
        site_name = kwargs[:name]
        container_mapper = config_mapper.containers.f(container_name)
        container_lib_mapper = lib_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(site_name)
        web_mapper = PathMapper.new('/web').f(container_name).f(site_name)

        # etc/sx
        expect_dir(container_mapper.sites)
        expect_dir(site_mapper)

        # var/lib/sx
        expect_dir(container_lib_mapper.web.f(site_name))

        # web
        expect_dir(web_mapper)
        expect_file_owner(web_mapper, container_name)
      end

      def site_delete_exps(**kwargs)
        config_mapper = site_controller.config
        lib_mapper = site_controller.lib
        container_name = kwargs[:container_name] || @container_name
        site_name = kwargs[:name]
        container_mapper = config_mapper.containers.f(container_name)
        container_lib_mapper = lib_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(site_name)
        web_mapper = PathMapper.new('/web').f(container_name).f(site_name)

        # etc/sx
        not_expect_dir(site_mapper)

        # var/lib/sx
        not_expect_dir(container_lib_mapper.web.f(site_name))
        not_expect_dir(container_lib_mapper.registry.sites.f(site_name))

        # web
        not_expect_dir(web_mapper)
      end

      def site_rename_exps(**kwargs)
        site_add_exps(name: kwargs.delete(:new_name))
        site_delete_exps(name: kwargs.delete(:name))
      end

      def site_alias_add_exps(**kwargs)
        alias_name = kwargs.delete(:name)
        config_mapper = site_controller.config
        container_name = @container_name
        container_mapper = config_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(@site_name)

        expect_file(site_mapper.aliases)
        expect_in_file(site_mapper.aliases, /^#{alias_name}$/)
      end

      def site_alias_delete_exps(**kwargs)
        alias_name = kwargs.delete(:name)
        config_mapper = site_controller.config
        container_name = @container_name
        container_mapper = config_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(@site_name)

        not_expect_file(site_mapper.aliases)
        not_expect_in_file(site_mapper.aliases, /^#{alias_name}$/)
      end

      def with_site
        site_add_with_exps(name: @site_name, container_name: @container_name)
        yield @site_name
        site_delete_with_exps(name: @site_name)
      end

      included do
        before :each do
          @site_name = "testS#{SecureRandom.hex[0..5]}.com"
        end
      end
    end
  end
end
