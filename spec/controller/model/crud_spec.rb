describe Superhosting::Controller::Model do
  include SpecHelpers::Controller::Model
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'list' do
    expect(model_list_with_exps[:data]).to including('joomla_v3_l', 'test_with_mux', 'symfony_m', 'fcgi_m')
  end

  it 'tree' do
    expect(model_tree_with_exps(name: 'test')).to include(:data) # TODO
  end

  it 'inspect' do
    expect(model_inspect_with_exps(name: 'test')).to include(:data) # TODO
  end

  it 'inheritance' do
    expect(model_inheritance_with_exps(name: 'test')).to include(:data) # TODO
  end

  it 'options' do
    expect(model_options_with_exps(name: 'test')).to include(:data) # TODO
  end

  it 'reconfig', :docker do
    with_container(model: 'test_with_mux') do |container_name|
      with_site do |site_name|
        model_reconfigure_with_exps(name: 'test_with_mux')
      end
    end
  end

  it 'update', :docker do
    begin
      with_container do |container_name|
        with_container(name: "#{@container_name}2", model: 'test') do |container2_name|
          expect(docker_api.container_image?(container2_name, 'sx-base')).to be_truthy
          command!('docker tag -f sx-almost-base superhosting/test')
          model_update_with_exps(name: 'test')
          expect(docker_api.container_image?(container_name, 'sx-base')).to be_truthy
          expect(docker_api.container_image?(container2_name, 'sx-base')).to be_falsey
          expect(docker_api.container_image?(container2_name, 'sx-almost-base')).to be_truthy
        end
      end
    ensure
      command!('docker tag -f sx-base superhosting/test')
    end
  end

  # negative

  it 'reconfig:model_does_not_used' do
    model_reconfigure_with_exps(name: 'test_with_mux', code: :model_does_not_used)
  end
end
