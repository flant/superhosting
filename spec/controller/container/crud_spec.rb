require_relative 'spec_helpers'

describe Superhosting::Controller::Container do
  include SpecHelpers::Controller::Container

  xit 'add' do
    container_add(name: 'test-container-1')
  end
end
