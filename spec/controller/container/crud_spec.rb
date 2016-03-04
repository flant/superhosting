require_relative 'spec_helpers'

describe Superhosting::Controller::Container do
  include SpecHelpers::Controller::Container

  before :each do
    @container_name = "test_#{SecureRandom.hex[0..5]}"
  end

  it 'add' do
    container_add(name: @container_name)
  end

  it 'delete' do
    container_add(name: @container_name)
    container_delete(name: @container_name)
  end
end
