module Superhosting
  module Patches
    module PathMapper
      module Debug
        module NullNode
          include Superhosting::Helper::Logger

          def create!
            self.debug_operation(desc: { code: :directories_create, data: { path: @path } }) do
              super
            end
          end

          def put!(content)
            self.debug_operation(desc: { code: :file_create, data: { path: @path } }) do
              super
            end
          end

          def rename!(new_path)
            self.debug_operation(desc: { code: :file_rename, data: { path: @path, new_path: new_path } }) do
              super
            end
          end

          def append!(content)
            self.debug_operation(desc: { code: :file_create, data: { path: @path } }) do
              super
            end
          end
        end
      end
    end
  end
end

::PathMapper::NullNode.send(:prepend, Superhosting::Patches::PathMapper::Debug::NullNode)