describe 'Superhosting::Controller::Model (cli)' do
  include SpecHelpers::Controller::Model
  include SpecHelpers::Controller::Container

  it 'model list' do
    expect { self.cli('model', 'list') }.to_not raise_error
  end

  it 'model reconfigure' do
    with_container do
      expect { self.cli('model', 'reconfigure', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model tree' do
    expect { self.cli('model', 'tree', 'test_with_mux') }.to_not raise_error
  end

  it 'model update' do
    with_container do
      expect { self.cli('model', 'update', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model inspect' do
    with_container do
      expect { self.cli('model', 'inspect', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model inheritance' do
    with_container do
      expect { self.cli('model', 'inheritance', 'fcgi_m') }.to_not raise_error
    end
  end

  it 'model options' do
    with_container do
      expect { self.cli('model', 'options', 'fcgi_m') }.to_not raise_error
    end
  end
end
