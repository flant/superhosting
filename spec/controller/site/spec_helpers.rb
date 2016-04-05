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

      def site_reconfigure(**kwargs)
        site_controller.reconfigure(**kwargs)
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

      def site_base(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        name = kwargs[:name] || @site_name
        container_etc_mapper = self.config.containers.f(container_name)
        container_lib_mapper = self.lib.containers.f(container_name)
        etc_mapper = container_etc_mapper.sites.f(name)
        web_mapper = self.web.f(container_name).f(name)
        lib_mapper = self.lib.containers.f(container_name).web.f(name)
        state_mapper = self.lib.containers.f(container_name).sites.f(name).state

        yield name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper
      end

      def site_add_exps(**kwargs)
        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          # /etc/sx
          expect_dir(container_etc_mapper.sites)
          expect_dir(etc_mapper)

          # model
          model_name = container_etc_mapper.f('model', default: self.config.default_model)
          self.model_exps(:"site_add_#{model_name}_exps", **kwargs)

          # /var/sx
          expect_dir(lib_mapper)
          expect_file(state_mapper)

          # /web
          expect_dir(web_mapper)
          expect_file_owner(web_mapper, container_name)
        end
      end

      def site_delete_exps(**kwargs)
        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          # /etc/sx
          not_expect_dir(etc_mapper)

          # model
          model_name = container_etc_mapper.f('model', default: self.config.default_model)
          self.model_exps(:"site_delete_#{model_name}_exps", **kwargs)

          # /var/sx
          not_expect_dir(lib_mapper)
          not_expect_dir(container_lib_mapper.registry.sites.f(name))
          not_expect_dir(state_mapper.parent)
          not_expect_file(state_mapper)

          # /web
          not_expect_dir(web_mapper)
        end
      end

      def site_rename_exps(**kwargs)
        site_add_exps(name: kwargs.delete(:new_name))
        site_delete_exps(name: kwargs.delete(:name))
      end

      def site_alias_add_exps(**kwargs)
        alias_name = kwargs.delete(:name)

        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          expect_file(etc_mapper.aliases)
          expect_in_file(etc_mapper.aliases, /^#{alias_name}$/)

          model_name = container_etc_mapper.f('model', default: self.config.default_model)
          self.model_exps(:"site_alias_#{model_name}_exps", **kwargs)
        end
      end

      def site_alias_delete_exps(**kwargs)
        alias_name = kwargs.delete(:name)

        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          model_name = container_etc_mapper.f('model', default: self.config.default_model)
          self.model_exps(:"site_alias_#{model_name}_exps", **kwargs)

          not_expect_file(etc_mapper.aliases)
          not_expect_in_file(etc_mapper.aliases, /^#{alias_name}$/)
        end
      end

      def site_add_fcgi_m_exps(**kwargs)
        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          nginx_mapper = self.etc.nginx.sites
          config_name = "#{container_name}-#{name}.conf"
          expect_file(nginx_mapper.f(config_name))
          expect_in_file(nginx_mapper.f(config_name), "access_log /web/#{container_name}/logs/#{name}_access_nginx.log main")
          expect_in_file(nginx_mapper.f(config_name), "root #{web_mapper.path}/;")
        end
      end

      def site_delete_fcgi_m_exps(**kwargs)
        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          nginx_mapper = self.etc.nginx.sites
          not_expect_file(nginx_mapper.f("#{container_name}-#{name}.conf"))
        end
      end

      def site_alias_fcgi_m_exps(**kwargs)
        self.site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, container_name, container_etc_mapper, container_lib_mapper|
          nginx_mapper = self.etc.nginx.sites
          config_name = "#{container_name}-#{name}.conf"
          expect_in_file(nginx_mapper.f(config_name), "server_name #{([name] + etc_mapper.aliases.lines).map(&:punycode).join(' ')};")
        end
      end

      # other

      def with_site(**kwargs, &b)
        self.with_base('site', default: { name: @site_name, container_name: @container_name }, **kwargs, &b)
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
