require_relative 'spec_helpers'

describe Superhosting::Controllers::Container do
  include SpecHelpers::Controllers::Container

  it 'add' do
    add_container(name: 'test-container')
  end
end
