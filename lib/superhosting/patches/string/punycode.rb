module Superhosting
  module Patches
    module String
      module Punycode
        def punycode
          parts = self.split('.').map do |label|
            encoded = ::Punycode.encode(Unicode::normalize_KC(Unicode::downcase(label)))
            if encoded =~ /-$/
              encoded.chop!
            else
              'xn--' + encoded
            end
          end
          parts.join('.')
        end
      end
    end
  end
end

String.send(:include, Superhosting::Patches::String::Punycode)