describe 'Superhosting::Controller::Container (cli)' do
  include SpecHelpers::Controller::Admin
  include SpecHelpers::Controller::Container

  def add_container
    self.container_add(name: @container_name)
  end
  
  it 'container add' do
    expect { self.cli('container', 'add', @container_name) }.to_not raise_error
  end

  it 'container change' do
    with_container do |container_name|
      expect { self.cli('container', 'change', container_name) }.to_not raise_error
    end
  end

  it 'container delete' do
    add_container
    expect { self.cli('container', 'delete', @container_name) }.to_not raise_error
  end

  it 'container model' do
    add_container
    expect { self.cli('container', 'model', @container_name) }.to_not raise_error
  end

  it 'container tree' do
    add_container
    expect { self.cli('container', 'tree', @container_name) }.to_not raise_error
  end

  it 'container inspect' do
    with_container do |container_name|
      expect { self.cli('container', 'inspect', container_name) }.to_not raise_error
    end
  end

  it 'container inheritance' do
    with_container do |container_name|
      expect { self.cli('container', 'inheritance', container_name) }.to_not raise_error
    end
  end

  it 'container list' do
    expect { self.cli('container', 'list') }.to_not raise_error
  end

  it 'container reconfigure' do
    with_container do |container_name|
      expect { self.cli('container', 'reconfigure', container_name) }.to_not raise_error
    end
  end

  it 'container rename' do
    add_container
    expect { self.cli('container', 'rename', @container_name, '-r', 'test_container_name') }.to_not raise_error
  end

  it 'container restore' do
    expect { self.cli('container', 'restore', @container_name) }.to_not raise_error
  end

  it 'container save' do
    expect { self.cli('container', 'save', @container_name) }.to_not raise_error
  end

  it 'container update' do
    with_container do |container_name|
      expect { self.cli('container', 'update', container_name) }.to_not raise_error
    end
  end

  it 'container admin add' do
    with_container do |container_name|
      with_admin do |admin_name|
        expect { self.cli('container', 'admin', 'add', admin_name, '-c', container_name) }.to_not raise_error
      end
    end
  end

  it 'container admin delete' do
    with_container do |container_name|
      with_admin do |admin_name|
        self.cli('container', 'admin', 'add', admin_name, '-c', container_name)
        expect { self.cli('container', 'admin', 'delete', admin_name, '-c', container_name) }.to_not raise_error
      end
    end
  end

  it 'container admin list' do
    with_container do |container_name|
      expect { self.cli('container', 'admin', 'list', '-c', container_name) }.to_not raise_error
    end
  end
end
