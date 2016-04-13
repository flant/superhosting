describe 'Superhosting::Controller::Mux (cli)' do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container

  it 'mux reconfigure', :docker do
    with_container model: 'bitrix_m' do
      expect { self.cli('mux', 'reconfigure', 'mux-php-5.5') }.to_not raise_error
    end
  end
end
