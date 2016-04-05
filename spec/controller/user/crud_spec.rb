require_relative 'spec_helpers'

describe Superhosting::Controller::User do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::User

  # positive

  it 'add' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name)
    end
  end

  it 'delete' do
    with_container do |container_name|
      with_user
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
        user_passwd_with_exps(name: user_name, container_name: container_name, generate: true)
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

  # negative

  it 'add:invalid_user_name' do
    invalid_user_names = ["l#{?o*25}ngname", "name!"]
    with_container do |container_name|
      invalid_user_names.each {|name| user_add_with_exps(name: name, container_name: container_name, code: :invalid_user_name) }
    end
  end

  it 'add:container_does_not_exists' do
    user_add_with_exps(name: @user_name, container_name: @container_name, code: :container_does_not_exists)
  end

  it 'add:user_exists' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name)
      user_add_with_exps(name: @user_name, container_name: container_name, code: :user_exists)
    end
  end

  it 'add:option_ftp_only_is_required' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name, ftp_dir: 'site', code: :option_ftp_only_is_required)
    end
  end

  it 'add:incorrect_ftp_dir' do
    with_container do |container_name|
      user_add_with_exps(name: @user_name, container_name: container_name, ftp_dir: 'site', ftp_only: true, code: :incorrect_ftp_dir)
    end
  end

  it 'delete:container_does_not_exists' do
    user_delete_with_exps(name: @user_name, container_name: @container_name, code: :container_does_not_exists)
  end

  it 'delete:user_does_not_exists' do
    with_container do |container_name|
      user_delete_with_exps(name: @user_name, container_name: container_name, code: :user_does_not_exists)
    end
  end

  # other

  it 'recreate', :docker do
    with_container do |container_name|
      2.times.each { with_user }
    end
  end
end
