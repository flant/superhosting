require_relative 'spec_helpers'

describe Superhosting::Controller::User do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::User

  it 'add' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name)
    end
  end

  it 'delete' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name)
      user_delete_with_exps(name: @user_name, container_name: container_name)
    end
  end

  it 'list' do
    with_container do |container_name|
      with_user do |user_name|
        expect(user_list_with_exps(container_name: container_name)[:data]).to include("#{container_name}_#{user_name}")
      end
    end
  end

  it 'passwd' do
    with_container do |container_name|
      with_user do |user_name|
        user_passwd_with_exps(name: "#{container_name}_#{user_name}", generate: true)
      end
    end
  end

  it 'change' do
    with_container do |container_name|
      with_user do |user_name|
        user_change_with_exps(name: user_name, container_name: container_name)
      end
    end
  end
end
