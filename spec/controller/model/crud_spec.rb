require_relative 'spec_helpers'

describe Superhosting::Controller::Model do
  include SpecHelpers::Controller::Model

  # positive

  it 'list' do
    expect(model_list_with_exps[:data]).to including('joomla_v3_l', 'bitrix_m', 'symfony_m', 'fcgi_m')
  end
end
