require_relative 'spec_helpers'

describe Superhosting::Controller::Mux do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'reconfig' do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        mux_reconfigure_with_exps(name: 'mux-php-5.5')
      end
    end
  end

  # negative

  it 'reconfig:mux_does_not_exists' do
    mux_reconfigure_with_exps(name: 'mux-php-5.5', code: :mux_does_not_exists)
  end
end
