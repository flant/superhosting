require_relative 'spec_helpers'

describe Superhosting::Controller::Container do
  include SpecHelpers::Controller::Admin
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Container

  it 'add' do
    container_add_with_exps(name: @container_name)
  end

  it 'delete' do
    container_add_with_exps(name: @container_name)
    container_delete_with_exps(name: @container_name)
  end

  it 'list' do
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
end
