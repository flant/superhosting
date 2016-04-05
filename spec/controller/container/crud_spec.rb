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

  it 'reconfig' do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        container_reconfigure_with_exps(name: container_name)
      end
    end
  end

  it 'delete' do
    container_add_with_exps(name: @container_name)
    container_delete_with_exps(name: @container_name)
  end

  it 'list' do
    with_container do |container_name|
      expect(container_list_with_exps[:data].first).to include(:name, :state)
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
        container_admin_add_with_exps(name: admin_name)
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

  it 'add:container_exists' do
    container_add_with_exps(name: @container_name)
    container_add_with_exps(name: @container_name, model: :incorrect_model_name, code: :container_exists)
  end

  it 'add:invalid_container_name' do
    invalid_names = [:s, :'!incorrectsymbol']
    invalid_names.each {|name| container_add_with_exps(name: name, code: :invalid_container_name) }
  end

  it 'add:model_does_not_exists' do
    container_add_with_exps(name: @container_name, model: :incorrect_model_name, code: :model_does_not_exists)
  end

  it 'reconfig:container_does_not_exists' do
    container_reconfigure_with_exps(name: @container_name, code: :container_does_not_exists)
  end

  it 'delete:container_does_not_exists' do
    container_delete_with_exps(name: @container_name, code: :container_does_not_exists)
  end

  it 'admin_add:admin_does_not_exists' do
    with_container do |container_name|
      container_admin_add_with_exps(name: @admin_name, code: :admin_does_not_exists)
    end
  end

  it 'admin_delete:admin_does_not_exists' do
    with_container do |container_name|
      container_admin_add_with_exps(name: 'incorrect_admin_name', code: :admin_does_not_exists)
    end
  end

  # other

  it 'add#mux', :docker do
    container_add_with_exps(name: @container_name, model: 'bitrix_m')
    expect(docker_api.container_running?('mux-php-5.5')).to be true
    container_add_with_exps(name: "#{@container_name}2", model: 'bitrix_m')
    container_delete_with_exps(name: @container_name)
    expect(docker_api.container_running?('mux-php-5.5')).to be true
    container_delete_with_exps(name: "#{@container_name}2")
    expect(docker_api.container_running?('mux-php-5.5')).to be false
  end

  it 'recreate', :docker do
    container_add_with_exps(name: @container_name)
    container_delete_with_exps(name: @container_name)
    container_add_with_exps(name: @container_name)
    container_delete_with_exps(name: @container_name)
  end
end
