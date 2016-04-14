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
end
