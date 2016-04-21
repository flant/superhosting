describe 'Superhosting::Controller::Mux (cli)' do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container

  it 'mux reconfigure', :docker do
    with_container model: 'test_with_mux' do
      expect { cli('mux', 'reconfigure', 'test') }.to_not raise_error
    end
  end

  it 'mux update', :docker do
    with_container model: 'test_with_mux' do
      expect { cli('mux', 'update', 'test') }.to_not raise_error
    end
  end

  it 'mux tree' do
    expect { cli('mux', 'tree', 'test') }.to_not raise_error
  end

  it 'mux inspect' do
    expect { cli('mux', 'inspect', 'test') }.to_not raise_error
    expect { cli('mux', 'inspect', 'test', '--inheritance') }.to_not raise_error
  end

  it 'mux inheritance' do
    expect { cli('mux', 'inheritance', 'test') }.to_not raise_error
    expect { cli('mux', 'inheritance', 'test', '--json') }.to_not raise_error
  end

  it 'mux options' do
    expect { cli('mux', 'options', 'test') }.to_not raise_error
    expect { cli('mux', 'options', 'test', '--inheritance') }.to_not raise_error
  end
end
