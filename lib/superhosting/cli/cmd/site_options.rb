module Superhosting
  module Cli
    module Cmd
      class SiteOptions < Base
        option :inheritance,
               :long  => '--inheritance',
               :boolean => true

        option :erb,
               :long  => '--erb',
               :boolean => true

        def self.has_required_param?
          true
        end

        def self.after_action(data, config)
          if config[:inheritance]
            data.each do |elm|
              elm.each do |name, options|
                next if options.empty?
                self.info(name)
                self.indent_step
                options.each {|k,v| self.info("#{k} = \"#{v}\"") }
                self.indent_step_back
              end
            end
          else
            data.each {|k,v| self.info("#{k} = \"#{v}\"") }
          end
        end
      end
    end
  end
end