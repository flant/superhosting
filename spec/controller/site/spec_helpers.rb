module SpecHelpers
  module Controller
    module Site
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def site_controller
        @site_controller ||= Superhosting::Controller::Site.new(docker_api: docker_api)
      end

      # methods

      def site_add(**kwargs)
        site_controller.add(**kwargs)
      end

      def site_name(**kwargs)
        site_controller.name(**kwargs)
      end

      def site_container(**kwargs)
        site_controller.container(**kwargs)
      end

      def site_delete(**kwargs)
        site_controller.delete(**kwargs)
      end

      def site_rename(**kwargs)
        site_controller.rename(**kwargs)
      end

      def site_move(**kwargs)
        site_controller.move(**kwargs)
      end

      def site_reconfigure(**kwargs)
        site_controller.reconfigure(**kwargs)
      end

      def site_list(**kwargs)
        site_controller.list(**kwargs)
      end

      def site_inspect(**kwargs)
        site_controller.inspect(**kwargs)
      end

      def site_inheritance(**kwargs)
        site_controller.inheritance(**kwargs)
      end

      def site_options(**kwargs)
        site_controller.options(**kwargs)
      end

      def site_alias_add(**kwargs)
        site_controller.alias(name: @site_name).add(**kwargs)
      end

      def site_alias_delete(**kwargs)
        site_controller.alias(name: @site_name).delete(**kwargs)
      end

      def site_alias_list(**_kwargs)
        site_controller.alias(name: @site_name).list
      end

      # expectations

      def site_base(**kwargs)
        container_name = kwargs[:container_name] || @container_name
        name = kwargs[:name] || @site_name
        container_etc_mapper = container_etc(container_name)
        container_lib_mapper = container_lib(container_name)
        etc_mapper = site_etc(container_name, name)
        lib_mapper = site_lib(container_name, name)
        web_mapper = site_web(container_name, name)
        state_mapper = site_state(container_name, name)
        aliases_mapper = site_aliases(container_name, name)

        yield name, etc_mapper, lib_mapper, web_mapper, state_mapper, aliases_mapper, container_name, container_etc_mapper, container_lib_mapper
      end

      def site_add_exps(**kwargs)
        site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, _aliases_mapper, container_name, container_etc_mapper, _container_lib_mapper|
          # index
          expect(site_controller.index).to include(name)
          expect(site_controller.index[name].container_mapper.name).to eq container_name

          # /etc/sx
          expect_dir(container_etc_mapper.sites)
          expect_dir(etc_mapper)

          # model
          model_name = container_etc_mapper.f('model', default: config.default_model)
          model_exps(:"site_add_#{model_name}_exps", **kwargs)

          # /var/sx
          expect_dir(lib_mapper)
          expect_file(state_mapper)

          # /web
          expect_dir(web_mapper)
          expect_file_owner(web_mapper, container_name)
        end
      end

      def site_delete_exps(**kwargs)
        site_base(**kwargs) do |name, etc_mapper, lib_mapper, web_mapper, state_mapper, aliases_mapper, _container_name, container_etc_mapper, container_lib_mapper|
          # /etc/sx
          not_expect_dir(etc_mapper)

          # model
          model_name = container_etc_mapper.f('model', default: config.default_model)
          model_exps(:"site_delete_#{model_name}_exps", **kwargs)

          # /var/sx
          not_expect_dir(lib_mapper)
          not_expect_dir(container_lib_mapper.registry.sites.f(name))
          not_expect_dir(state_mapper.parent)
          not_expect_file(state_mapper)
          not_expect_file(aliases_mapper)

          # /web
          not_expect_dir(web_mapper)
        end
      end

      def site_rename_exps(**kwargs)
        site_add_exps(name: kwargs.delete(:new_name))
        site_delete_exps(name: kwargs.delete(:name))
      end

      def site_move_exps(**kwargs)
        site_add_exps(name: kwargs.delete(:new_name), container_name: kwargs.delete(:new_container_name))
        site_delete_exps(name: kwargs.delete(:name))
      end

      def site_alias_add_exps(**kwargs)
        alias_name = kwargs.delete(:name)

        site_base(**kwargs) do |_name, _etc_mapper, _lib_mapper, _web_mapper, _state_mapper, aliases_mapper, _container_name, container_etc_mapper, _container_lib_mapper|
          expect_file(aliases_mapper)
          expect_in_file(aliases_mapper, /^#{alias_name}$/)

          model_name = container_etc_mapper.f('model', default: config.default_model)
          model_exps(:"site_alias_#{model_name}_exps", **kwargs)
        end
      end

      def site_alias_delete_exps(**kwargs)
        alias_name = kwargs.delete(:name)

        site_base(**kwargs) do |_name, _etc_mapper, _lib_mapper, _web_mapper, _state_mapper, aliases_mapper, _container_name, container_etc_mapper, _container_lib_mapper|
          model_name = container_etc_mapper.f('model', default: config.default_model)
          model_exps(:"site_alias_#{model_name}_exps", **kwargs)

          not_expect_file(aliases_mapper)
          not_expect_in_file(aliases_mapper, /^#{alias_name}$/)
        end
      end

      def site_add_fcgi_m_exps(**kwargs)
        site_base(**kwargs) do |name, _etc_mapper, _lib_mapper, web_mapper, _state_mapper, _aliases_mapper, container_name, _container_etc_mapper, _container_lib_mapper|
          nginx_mapper = etc.nginx.sites
          config_name = "#{container_name}-#{name}.conf"
          expect_file(nginx_mapper.f(config_name))
          expect_in_file(nginx_mapper.f(config_name), "access_log /web/#{container_name}/logs/#{name}_access_nginx.log main")
          expect_in_file(nginx_mapper.f(config_name), "root #{web_mapper.path}/;")
        end
      end

      def site_delete_fcgi_m_exps(**kwargs)
        site_base(**kwargs) do |name, _etc_mapper, _lib_mapper, _web_mapper, _state_mapper, _aliases_mapper, container_name, _container_etc_mapper, _container_lib_mapper|
          nginx_mapper = etc.nginx.sites
          not_expect_file(nginx_mapper.f("#{container_name}-#{name}.conf"))
        end
      end

      def site_alias_fcgi_m_exps(**kwargs)
        site_base(**kwargs) do |name, _etc_mapper, _lib_mapper, _web_mapper, _state_mapper, aliases_mapper, container_name, _container_etc_mapper, _container_lib_mapper|
          nginx_mapper = etc.nginx.sites
          config_name = "#{container_name}-#{name}.conf"
          expect_in_file(nginx_mapper.f(config_name), "server_name #{([name] + aliases_mapper.lines).map(&:punycode).join(' ')};")
        end
      end

      # other

      def with_site(**kwargs, &b)
        with_base('site', default: { name: @site_name, container_name: @container_name }, **kwargs, &b)
      end

      def with_site_alias(**kwargs, &b)
        with_container do |container_name|
          with_site do |site_name|
            alias_name = "alias-#{@site_name}"
            with_base('site_alias', default: { name: alias_name },
                                    to_yield: [container_name, site_name, alias_name], **kwargs, &b)
          end
        end
      end

      included do
        before :each do
          @site_name = "tS#{SecureRandom.hex[0..5]}.com"
        end

        after :each do
          with_logger(logger: false) do
            command('rm -rf /etc/nginx/sites/tS*')
          end
        end
      end
    end
  end
end
