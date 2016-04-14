describe 'Superhosting::Controller::User (cli)' do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::User

  def add_container_user
    container_add(name: @container_name)
    self.cli('user', 'add', @user_name, '-c', @container_name)
  end

  it 'user add' do
    expect { add_container_user }.to_not raise_error
  end

  it 'user change' do
    add_container_user
    expect { self.cli('user', 'change', @user_name, '-c', @container_name) }.to_not raise_error
  end

  it 'user delete' do
    add_container_user
    expect { self.cli('user', 'delete', @user_name, '-c', @container_name) }.to_not raise_error
  end

  it 'user list' do
    add_container_user
    expect { self.cli('user', 'list', '-c', @container_name) }.to_not raise_error
  end

  it 'user passwd' do
    add_container_user
    expect { self.cli('user', 'passwd', '-g', @user_name, '-c', @container_name) }.to_not raise_error
  end
end
