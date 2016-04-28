module SpecHelpers
  module Controller
    module Mysql
      extend ActiveSupport::Concern
      include SpecHelpers::Base

      def mysql_controller
        @mysql_controller ||= Superhosting::Controller::Mysql.new(docker_api: docker_api)
      end

      def mysql_client
        mysql_controller.client
      end

      # methods

      def mysql_user_add(**kwargs)
        mysql_controller.user.add(**kwargs)
      end

      def mysql_user_delete(**kwargs)
        mysql_controller.user.delete(**kwargs)
      end

      def mysql_db_add(**kwargs)
        mysql_controller.db.add(**kwargs)
      end

      def mysql_db_delete(**kwargs)
        mysql_controller.db.delete(**kwargs)
      end

      # expectations

      def alternative_name(**kwargs)
        [kwargs[:container_name], kwargs[:name]].compact.join('_')
      end

      def mysql_user_add_exps(**kwargs)
        user_name = alternative_name(**kwargs)
        container_name = user_name.split('_').first
        expect(mysql_controller.user.index).to include(alternative_name(**kwargs))

        if (databases = kwargs[:databases])
          databases.each do |db_name|
            db_name = alternative_name(name: db_name, container_name: container_name) unless db_name.start_with? container_name
            mysql_db_add_exps(name: db_name)
            expect(mysql_controller.user.grant_index).to include(db_name)
            expect(mysql_controller.user.grant_index[db_name]).to include(user_name)
          end
        end
      end

      def mysql_user_delete_exps(**kwargs)
        expect(mysql_controller.user.index).to_not include(alternative_name(**kwargs))
      end

      def mysql_db_add_exps(**kwargs)
        db_name = alternative_name(**kwargs)
        container_name = db_name.split('_').first
        expect(mysql_controller.db.index).to include(alternative_name(**kwargs))
        
        if (users = kwargs[:users])
          users.each do |user_name|
            user_name = alternative_name(name: user_name, container_name: container_name) unless user_name.start_with? container_name
            mysql_user_add_exps(name: user_name)
            expect(mysql_controller.user.grant_index).to include(db_name)
            expect(mysql_controller.user.grant_index[db_name]).to include(user_name)
          end
        end
      end

      def mysql_db_delete_exps(**kwargs)
        db_name = alternative_name(**kwargs)
        expect(mysql_controller.db.index).to_not include(db_name)
      end

      # other

      def with_mysql_db(**kwargs, &b)
        with_container do |container_name|
          with_base('mysql_db', default: { name: alternative_name(name: @mysql_db_name,
                                                                  container_name: container_name) },
                                to_yield: [container_name, @mysql_db_name], **kwargs, &b)
        end
      end

      def with_mysql_user(**kwargs, &b)
        with_container do |container_name|
          with_base('mysql_user', default: { name: alternative_name(name: @mysql_user_name,
                                                                    container_name: container_name) },
                    to_yield: [container_name, @mysql_user_name], **kwargs, &b)
        end
      end

      included do
        before :each do
          @mysql_user_name = "tMU#{SecureRandom.hex[0..3]}"
          @mysql_db_name = "tMDB#{SecureRandom.hex[0..3]}"
        end
      end
    end
  end
end
