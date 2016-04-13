describe 'Superhosting::Controller::Admin (cli)' do
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Admin

  it 'admin add' do
    expect { self.cli('admin', 'add', '-g', @admin_name) }.to_not raise_error
  end

  it 'admin delete' do
    self.cli('admin', 'add', '-g', @admin_name)
    expect { self.cli('admin', 'delete', @admin_name) }.to_not raise_error
  end

  it 'admin list' do
    expect { self.cli('admin', 'list') }.to_not raise_error
  end

  it 'admin passwd' do
    self.cli('admin', 'add', '-g', @admin_name)
    expect { self.cli('admin', 'passwd', '-g', @admin_name) }.to_not raise_error
  end

  it 'admin container add' do
    with_admin do |admin_name|
      with_container do |container_name|
        expect { self.cli('admin', 'container', 'add', container_name, '-a', admin_name) }.to_not raise_error
      end
    end
  end

  it 'admin container delete' do
    with_admin do |admin_name|
      with_container do |container_name|
        self.cli('admin', 'container', 'add', container_name, '-a', admin_name)
        expect { self.cli('admin', 'container', 'delete', container_name, '-a', admin_name) }.to_not raise_error
      end
    end
  end

  it 'admin container list' do
    with_admin do |admin_name|
      expect { self.cli('admin', 'container', 'list', '-a', admin_name) }.to_not raise_error
    end
  end
end
