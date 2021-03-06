describe 'Superhosting::Controller::Container (cli)' do
  include SpecHelpers::Controller::Admin
  include SpecHelpers::Controller::Container

  def add_container
    container_add_with_exps(name: @container_name)
  end

  it 'container add' do
    expect { cli('container', 'add', @container_name) }.to_not raise_error
  end

  it 'container delete' do
    add_container
    expect { cli('container', 'delete', @container_name) }.to_not raise_error
  end

  it 'container model name' do
    add_container
    expect { cli('container', 'model', 'name', '-c', @container_name) }.to_not raise_error
  end

  it 'container tree' do
    add_container
    expect { cli('container', 'model', 'tree', '-c', @container_name) }.to_not raise_error
  end

  it 'container inspect' do
    with_container do |container_name|
      expect { cli('container', 'inspect', container_name) }.to_not raise_error
      expect { cli('container', 'inspect', container_name, '--inheritance') }.to_not raise_error
      expect { cli('container', 'inspect', container_name, '--erb') }.to_not raise_error
    end
  end

  it 'container inheritance' do
    with_container do |container_name|
      expect { cli('container', 'inheritance', container_name) }.to_not raise_error
      expect { cli('container', 'inheritance', container_name, '--json') }.to_not raise_error
    end
  end

  it 'container options' do
    with_container do |container_name|
      expect { cli('container', 'options', container_name) }.to_not raise_error
      expect { cli('container', 'options', container_name, '--inheritance') }.to_not raise_error
      expect { cli('container', 'options', container_name, '--erb') }.to_not raise_error
    end
  end

  it 'container list' do
    add_container
    expect { cli('container', 'list') }.to_not raise_error
    expect { cli('container', 'list', '--json') }.to_not raise_error
    expect { cli('container', 'list', '--state') }.to_not raise_error
  end

  it 'container reconfigure' do
    with_container do |container_name|
      expect { cli('container', 'reconfigure', container_name) }.to_not raise_error
    end
  end

  it 'container rename' do
    add_container
    expect { cli('container', 'rename', @container_name, '-r', 'tC_rename') }.to_not raise_error
  end

  it 'container restore' do
    expect { cli('container', 'restore', @container_name) }.to_not raise_error
  end

  it 'container save' do
    expect { cli('container', 'save', @container_name) }.to_not raise_error
  end

  it 'container update' do
    with_container do |container_name|
      expect { cli('container', 'update', container_name) }.to_not raise_error
    end
  end

  it 'container admin add' do
    with_container do |container_name|
      with_admin do |admin_name|
        expect { cli('container', 'admin', 'add', admin_name, '-c', container_name) }.to_not raise_error
      end
    end
  end

  it 'container admin delete' do
    with_container do |container_name|
      with_admin do |admin_name|
        cli('container', 'admin', 'add', admin_name, '-c', container_name)
        expect { cli('container', 'admin', 'delete', admin_name, '-c', container_name) }.to_not raise_error
      end
    end
  end

  it 'container admin list' do
    with_container do |container_name|
      with_admin do
        container_admin_add(name: @admin_name)
        expect { cli('container', 'admin', 'list', '-c', container_name) }.to_not raise_error
        expect { cli('container', 'admin', 'list', '-c', container_name, '--json') }.to_not raise_error
      end
    end
  end
end
