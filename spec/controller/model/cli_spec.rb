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
    expect { self.cli('model', 'tree', 'bitrix_m') }.to_not raise_error
  end

  it 'model update' do
    expect { self.cli('model', 'update', 'bitrix_m') }.to_not raise_error
  end
end
