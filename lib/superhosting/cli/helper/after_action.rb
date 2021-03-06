module Superhosting
  module Cli
    module Helper
      module AfterAction
        include Superhosting::Helper::Logger

        def show_list(data, sort: true)
          data.sort! if sort
          data.each { |elm| info(elm) }
        end

        def show_data(data)
          info(data)
        end

        def show_json(data, sortby: nil)
          data.sort! { |a1, a2| a1[sortby] <=> a2[sortby] } unless sortby.nil?
          info(JSON.pretty_generate(data))
        end

        def show_site_list(data, config)
          data = data.uniq { |v| v['name'] }
          if config[:json]
            sites = data.map { |site_info| { 'name' => site_info['name'], 'state' => site_info['state'], 'container' => site_info['container'], 'aliases' => site_info['aliases'] } }
            show_json(sites, sortby: 'name')
          else
            data.each do |site_info|
              name = site_info['name']
              container = site_info['container']
              state = site_info['state']

              output = []
              output << container unless config[:container_name]
              output << name
              output << state if config[:state]

              info(output.join(' '))
            end
          end
        end

        def show_container_list(data, config)
          if config[:json]
            show_json(data.map { |container_info| { 'name' => container_info['name'], 'state' => container_info['state'] } }, sortby: 'name')
          else
            data.sort_by { |elm| elm['name'] }.each do |container_info|
              name = container_info['name']
              state = container_info['state']

              if config[:state]
                info([name, state].join(' '))
              else
                info(name)
              end
            end
          end
        end

        def show_model_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data.map { |elm| elm['name'] })
          end
        end

        def show_admin_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data.map { |admin| admin.keys.first })
          end
        end

        def show_alias_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data)
          end
        end

        def show_container_admin_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data.map { |admin| admin['admin'] })
          end
        end

        def show_admin_container_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data.map { |admin| admin['container'] })
          end
        end

        def show_user_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            data.each do |elm|
              elm.each do |users_type, users|
                info(users_type)
                indent_step
                show_list(users)
                indent_step_back
              end
            end
          end
        end

        def show_mysql_list(data, config)
          if config[:json]
            show_json(data, sortby: 'name')
          else
            show_list(data.map { |u| u['name'] })
          end
        end

        def show_options(data, config)
          show = lambda do |options|
            options.each { |k, v| info("#{k} = #{v.inspect}") }
          end

          if config[:inheritance]
            data.each do |elm|
              elm.each do |name, options|
                next if options.empty?
                info(name)
                indent_step
                show.call(options)
                indent_step_back
              end
            end
          else
            show.call(data)
          end
        end

        def show_inheritance(data, config)
          if config[:json]
            show_json(data)
          else
            show_list(data.map do |hash|
              type = hash['type']
              name = hash['name']
              "#{"#{type}: " if type == 'mux'}#{name}"
            end, sort: false)
          end
        end

        def show_mux_inheritance(data, config)
          if config[:json]
            show_json(data)
          else
            show_list(data.map { |hash| hash['name'] }, sort: false)
          end
        end

        def show_models_tree(data, ignore_type: false)
          show_tree = lambda do |node|
            show_node = lambda do |node_, type|
              node_.each do |k, hash|
                info("#{"#{type}: " if !ignore_type && type == 'mux'}#{k}")
                indent_step
                show_tree.call(hash)
                indent_step_back
              end
            end

            %w(model mux).each do |type|
              (node[type] || []).each { |v| show_node.call(v, type) }
            end
          end

          old = indent
          show_tree.call(data)
          self.indent = old
        end
      end
    end
  end
end
