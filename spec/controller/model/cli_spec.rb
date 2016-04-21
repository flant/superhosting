describe 'Superhosting::Controller::Model (cli)' do
  include SpecHelpers::Controller::Model
  include SpecHelpers::Controller::Container

  it 'model list' do
    expect { cli('model', 'list') }.to_not raise_error
    expect { cli('model', 'list', '--json', '--abstract') }.to_not raise_error
  end

  it 'model reconfigure' do
    with_container do
      expect { cli('model', 'reconfigure', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model tree' do
    expect { cli('model', 'tree', 'fcgi_m') }.to_not raise_error
  end

  it 'model update' do
    with_container do
      expect { cli('model', 'update', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model inspect' do
    with_container do
      expect { cli('model', 'inspect', 'fcgi_m') }.to_not raise_error
      expect { cli('model', 'inspect', 'fcgi_m', '--inheritance') }.to_not raise_error
    end
  end

  it 'model inheritance' do
    with_container do
      expect { cli('model', 'inheritance', 'fcgi_m') }.to_not raise_error
      expect { cli('model', 'inheritance', 'fcgi_m', '--json') }.to_not raise_error
    end
  end

  it 'model options' do
    with_container do
      expect { cli('model', 'options', 'fcgi_m') }.to_not raise_error
      expect { cli('model', 'options', 'fcgi_m', '--inheritance') }.to_not raise_error
    end
  end
end
