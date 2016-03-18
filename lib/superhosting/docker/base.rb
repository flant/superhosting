module Superhosting
  module Docker
    module Base
      def raw_connection
      end

      def resp_if_success(resp)
      end

      def container_info(name)
      end

      def container_list
      end

      def container_kill!(name)
      end

      def container_rm!(name)
      end

      def container_stop!(name)
      end

      def container_rm_inactive!(name)
      end

      def container_running?(name)
      end

      def container_exists?(name)
      end
    end
  end
end
