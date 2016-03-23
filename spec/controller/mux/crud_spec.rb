require_relative 'spec_helpers'

describe Superhosting::Controller::Mux do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  xit 'reconfig', :docker do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        container_registry_path = @container_controller.lib.containers.f(container_name).registry.container.path
        site_registry_path = @container_controller.lib.containers.f(container_name).registry.sites.f(site_name).path
        time_container = File.mtime(container_registry_path)
        time_site = File.mtime(site_registry_path)

        mux_reconfig_with_exps(name: 'php-5.5')

        expect(container_registry_path).not_to eq time_container
        expect(site_registry_path).not_to eq time_site
      end
    end
  end

  # negative

  it 'reconfig:mux_does_not_exists' do
    mux_reconfig_with_exps(name: 'php-5.5', code: :mux_does_not_exists)
  end
end
