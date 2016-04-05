require_relative 'spec_helpers'

describe Superhosting::Controller::Model do
  include SpecHelpers::Controller::Model
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'list' do
    expect(model_list_with_exps[:data]).to including('joomla_v3_l', 'bitrix_m', 'symfony_m', 'fcgi_m')
  end

  it 'reconfig' do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        model_reconfigure_with_exps(name: 'bitrix_m')
      end
    end
  end

  # negative

  it 'reconfig:model_does_not_used' do
    model_reconfigure_with_exps(name: 'bitrix_m', code: :model_does_not_used)
  end
end
