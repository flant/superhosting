module Superhosting
  module Helpers
    def instance_variables_to_hash(obj)
      obj.instance_variables.map do |name|
        [name.to_s[1..-1].to_sym, obj.instance_variable_get(name)]
      end.to_h
    end

    def create_conf(path, conf)
      File.open(path, 'w') {|f| f.write(conf) }
    end

    def write_if_not_exist(path, line)
      File.open(path, 'a+') do |f|
        f.puts(line) unless f.each_line.any? { |l| l =~ Regexp.new(line) }
      end
    end

    def remove_line_from_file(path, line)
      lines = File.readlines(path).select {|l| l !~ Regexp.new(line) }
      File.open(path, 'w') {|f| f.write lines.join('') }
    end

    def erb(node, vars)
      ERB.new(node).result(OpenStruct.new(vars).instance_eval { binding })
    rescue Exception => e
      raise NetStatus::Exception, e.net_status.merge!( message: "#{e.backtrace.first.sub! '(erb)', node._path}: #{e.message}")
    end
  end
end
