module Superhosting
  module Helpers
    include Helper::File
    include Helper::Erb

    def instance_variables_to_hash(obj)
      obj.instance_variables.map do |name|
        [name.to_s[1..-1].to_sym, obj.instance_variable_get(name)]
      end.to_h
    end
  end
end