describe 'Superhosting::Controller::Mux (cli)' do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container

  it 'mux reconfigure', :docker do
    with_container model: 'test_with_mux' do
      expect { self.cli('mux', 'reconfigure', 'test') }.to_not raise_error
    end
  end

  it 'mux update', :docker do
    with_container model: 'test_with_mux' do
      expect { self.cli('mux', 'update', 'test') }.to_not raise_error
    end
  end

  it 'mux tree' do
    expect { self.cli('mux', 'tree', 'test') }.to_not raise_error
  end

  it 'mux inspect' do
    expect { self.cli('mux', 'inspect', 'test') }.to_not raise_error
    expect { self.cli('mux', 'inspect', 'test', '--inheritance') }.to_not raise_error
  end

  it 'mux inheritance' do
    expect { self.cli('mux', 'inheritance', 'test') }.to_not raise_error
    expect { self.cli('mux', 'inheritance', 'test', '--json') }.to_not raise_error
  end

  it 'mux options' do
    expect { self.cli('mux', 'options', 'test') }.to_not raise_error
    expect { self.cli('mux', 'options', 'test', '--inheritance') }.to_not raise_error
  end
end
