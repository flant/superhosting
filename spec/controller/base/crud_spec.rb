require_relative 'spec_helpers'

describe Superhosting::Controller::Base do
  include SpecHelpers::Controller::Base
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'repair' do
    base_repair_with_exps
  end

  # other

  it 'repair@all' do
    def site_state_(name)
      self.site_state(name, "#{name}.rf")
    end

    first_container = @container_name
    second_container = "#{@container_name}2"
    third_container = "#{@container_name}3"
    [first_container, second_container, third_container].each do |container|
      container_add_with_exps(name: container)
      site_add_with_exps(name: "#{container}.rf", container_name: container)
    end

    container_state(first_container).put!('not_ok')
    site_state_(first_container).put!('not_ok')
    site_state_(second_container).put!('not_ok')
    container_state(third_container).put!('not_ok')
    site_state_(third_container).put!('not_ok')

    base_repair_with_exps

    [first_container, second_container, third_container].each do |container|
      expect(container_state(container).value).to eq 'up'
      expect(site_state_(container).value).to eq 'up'
    end
  end
end