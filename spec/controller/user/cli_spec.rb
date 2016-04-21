describe 'Superhosting::Controller::User (cli)' do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Admin

  def add_container_user
    container_add(name: @container_name)
    user_add(name: @user_name, container_name: @container_name)
  end

  it 'user add' do
    container_add(name: @container_name)
    expect { cli('user', 'add', @user_name, '-c', @container_name, '-g') }.to_not raise_error
  end

  it 'user change' do
    add_container_user
    expect { cli('user', 'change', @user_name, '-c', @container_name) }.to_not raise_error
  end

  it 'user delete' do
    add_container_user
    expect { cli('user', 'delete', @user_name, '-c', @container_name) }.to_not raise_error
  end

  it 'user list' do
    add_container_user
    with_admin do
      container_admin_add(name: @admin_name)
      expect { cli('user', 'list', '-c', @container_name) }.to_not raise_error
      expect { cli('user', 'list', '-c', @container_name, '--json') }.to_not raise_error
    end
  end

  it 'user passwd' do
    add_container_user
    expect { cli('user', 'passwd', '-g', @user_name, '-c', @container_name) }.to_not raise_error
  end
end
