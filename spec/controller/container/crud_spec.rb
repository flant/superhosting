require_relative 'spec_helpers'

describe Superhosting::Controller::Container do
  include SpecHelpers::Controller::Admin
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'add' do
    container_add_with_exps(name: @container_name)
  end

  it 'reconfig', :docker do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        container_registry_path = @container_controller.lib.containers.f(container_name).registry.container.path
        site_registry_path = @container_controller.lib.containers.f(container_name).registry.sites.f(site_name).path
        time_container = File.mtime(container_registry_path)
        time_site = File.mtime(site_registry_path)

        container_reconfig_with_exps(name: container_name)

        expect(container_registry_path).not_to eq time_container
        expect(site_registry_path).not_to eq time_site
      end
    end
  end

  it 'delete' do
    container_add_with_exps(name: @container_name)
    container_delete_with_exps(name: @container_name)
  end

  it 'list', :docker do
    with_container do |container_name|
      expect(container_list_with_exps[:data]).to include(container_name)
    end
  end

  it 'admin_add' do
    with_admin do |admin_name|
      with_container do |container_name|
        container_admin_add_with_exps(name: admin_name)
      end
    end
  end

  it 'admin_delete' do
    with_admin do |admin_name|
      with_container do |container_name|
        container_admin_delete_with_exps(name: admin_name)
      end
    end
  end

  it 'admin_list' do
    with_container_admin do |container_name, admin_name|
      expect(container_admin_list_with_exps[:data]).to include(admin: admin_name, user: "#{container_name}_admin_#{admin_name}")
    end
  end

  # negative

  it 'add:invalid_container_name' do
    invalid_names = [:s, :'!incorrectsymbol']
    invalid_names.each {|name| container_add_with_exps(name: name, code: :invalid_container_name) }
  end

  it 'add:container_is_running', :docker do
    container_add_with_exps(name: @container_name)
    container_add_with_exps(name: @container_name, code: :container_is_running)
  end

  it 'reconfig:container_does_not_exists' do
    container_reconfig_with_exps(name: @container_name, code: :container_does_not_exists)
  end

  it 'add:model_does_not_exists' do
    container_add_with_exps(name: @container_name, model: :incorrect_model_name, code: :model_does_not_exists)
  end

  it 'admin_add:admin_does_not_exists' do
    with_container do |container_name|
      container_admin_add_with_exps(name: @admin_name, code: :admin_does_not_exists)
    end
  end

  # other

  it 'add#recreate_inactive_container', :docker do
    container_add_with_exps(name: @container_name)
    docker_api.container_stop!(@container_name)
    container_add_with_exps(name: @container_name)
  end

  it 'add#mux', :docker do
    container_add_with_exps(name: @container_name, model: 'bitrix_m')
    expect(docker_api.container_running?('php-5.5')).to be true
    container_add_with_exps(name: "#{@container_name}2", model: 'bitrix_m')
    container_delete_with_exps(name: @container_name)
    expect(docker_api.container_running?('php-5.5')).to be true
    container_delete_with_exps(name: "#{@container_name}2")
    expect(docker_api.container_running?('php-5.5')).to be false
  end
end
