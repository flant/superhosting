module SpecHelpers
  module Controller
    module Site
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def site_controller
        @site_controller ||= Superhosting::Controller::Site.new(logger: logger)
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

      def site_reconfig(**kwargs)
        site_controller.reconfig(**kwargs)
      end

      def site_list(**kwargs)
        site_controller.list(**kwargs)
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

        # /etc/sx
        expect_dir(container_mapper.sites)
        expect_dir(site_mapper)

        # model
        model_name = container_mapper.f('model', default: config_mapper.default_model)
        self.model_exps(:"site_add_#{model_name}_exps", **kwargs)

        # /var/sx
        expect_dir(container_lib_mapper.web.f(site_name))
        expect_file(container_lib_mapper.sites.f(site_name).state)

        # /web
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

        # /etc/sx
        not_expect_dir(site_mapper)

        # model
        model_name = container_mapper.f('model', default: config_mapper.default_model)
        self.model_exps(:"site_delete_#{model_name}_exps", **kwargs)

        # /var/sx
        not_expect_dir(container_lib_mapper.web.f(site_name))
        not_expect_dir(container_lib_mapper.registry.sites.f(site_name))

        # /web
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

        model_name = container_mapper.f('model', default: config_mapper.default_model)
        self.model_exps(:"site_alias_#{model_name}_exps", **kwargs)
      end

      def site_alias_delete_exps(**kwargs)
        alias_name = kwargs.delete(:name)
        config_mapper = site_controller.config
        container_name = @container_name
        container_mapper = config_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(@site_name)

        model_name = container_mapper.f('model', default: config_mapper.default_model)
        self.model_exps(:"site_alias_#{model_name}_exps", **kwargs)

        not_expect_file(site_mapper.aliases)
        not_expect_in_file(site_mapper.aliases, /^#{alias_name}$/)
      end

      def site_add_fcgi_m_exps(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        site_name = kwargs[:name] || @site_name
        site_web_mapper = PathMapper.new('/web').f(container_name).f(site_name)
        nginx_sites_mapper = PathMapper.new('/etc').nginx.sites

        config_name = "#{container_name}-#{site_name}.conf"
        expect_file(nginx_sites_mapper.f(config_name))
        expect_in_file(nginx_sites_mapper.f(config_name), "access_log /web/#{container_name}/logs/#{site_name}_access_nginx.log main")
        expect_in_file(nginx_sites_mapper.f(config_name), "root #{site_web_mapper.path}/;")
      end

      def site_delete_fcgi_m_exps(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        site_name = kwargs[:name] || @site_name
        nginx_sites_mapper = PathMapper.new('/etc').nginx.sites

        not_expect_file(nginx_sites_mapper.f("#{container_name}-#{site_name}.conf"))
      end

      def site_alias_fcgi_m_exps(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        site_name = kwargs[:name] || @site_name
        config_mapper = site_controller.config
        container_mapper = config_mapper.containers.f(container_name)
        site_mapper = container_mapper.sites.f(site_name)
        nginx_sites_mapper = PathMapper.new('/etc').nginx.sites

        config_name = "#{container_name}-#{site_name}.conf"
        expect_in_file(nginx_sites_mapper.f(config_name), "server_name #{([site_name] + site_mapper.aliases.lines).map(&:punycode).join(' ')};")
      end

      # other

      def with_site(**kwargs)
        site_add_with_exps(name: @site_name, container_name: @container_name, **kwargs)
        yield @site_name
        site_delete_with_exps(name: @site_name)
      end

      included do
        before :each do
          @site_name = "testS#{SecureRandom.hex[0..5]}.com"
        end

        after :each do
          command("rm -rf /etc/nginx/sites/test*")
        end
      end
    end
  end
end
