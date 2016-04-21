describe 'Superhosting::Controller::Base (cli)' do
  include SpecHelpers::Controller::Base

  it 'repair' do
    expect { cli('repair') }.to_not raise_error
  end

  it 'update' do
    expect { cli('update') }.to_not raise_error
  end
end
