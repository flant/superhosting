require_relative 'spec_helpers'

describe Superhosting::Controller::Model do
  include SpecHelpers::Controller::Model
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'list' do
    expect(model_list_with_exps[:data]).to including('joomla_v3_l', 'bitrix_m', 'symfony_m', 'fcgi_m')
  end

  it 'reconfig' do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        container_registry_path = @container_controller.lib.containers.f(container_name).registry.container.path
        site_registry_path = @container_controller.lib.containers.f(container_name).registry.sites.f(site_name).path
        time_container = File.mtime(container_registry_path)
        time_site = File.mtime(site_registry_path)

        model_reconfigure_with_exps(name: 'bitrix_m')

        expect(container_registry_path).not_to eq time_container
        expect(site_registry_path).not_to eq time_site
      end
    end
  end

  # negative

  it 'reconfig:model_does_not_exists' do
    model_reconfigure_with_exps(name: 'bad_model', code: :model_does_not_exists)
  end
end
