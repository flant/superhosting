require_relative 'spec_helpers'

describe Superhosting::Controllers::Container do
  include SpecHelpers::Controllers::Container

  it 'add' do
    container_add(name: 'test-container-1')
  end
end
