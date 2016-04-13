describe 'Superhosting::Controller::Base (cli)' do
  include SpecHelpers::Controller::Base

  it 'repair' do
    expect { self.cli('repair') }.to_not raise_error
  end
end