describe Superhosting::Controller::Mux do
  include SpecHelpers::Controller::Mux
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'reconfig', :docker do
    with_container(model: 'test_with_mux') do |container_name|
      with_site do |site_name|
        mux_reconfigure_with_exps(name: 'test')
      end
    end
  end

  it 'update', :docker do
    begin
      with_container(model: 'test_with_mux') do |container_name|
        expect(docker_api.container_image?(container_name, 'sx-almost-base')).to be_truthy
        expect(docker_api.container_image?('mux-test', 'sx-mux')).to be_truthy
        command!('docker tag -f sx-base superhosting/ctestmux')
        command!('docker tag -f sx-base superhosting/testmux')
        mux_update_with_exps(name: 'test')
        expect(docker_api.container_image?(container_name, 'sx-almost-base')).to be_falsey
        expect(docker_api.container_image?('mux-test', 'sx-mux')).to be_falsey
        expect(docker_api.container_image?(container_name, 'sx-base')).to be_truthy
        expect(docker_api.container_image?('mux-test', 'sx-base')).to be_truthy
      end
    ensure
      command!('docker tag -f sx-almost-base superhosting/ctestmux')
      command!('docker tag -f sx-mux superhosting/testmux')
    end
  end

  it 'tree' do
    expect(mux_tree_with_exps(name: 'test')).to include(:data)
  end

  it 'inspect' do
    expect(mux_inspect_with_exps(name: 'test')).to include(:data)
  end

  it 'inheritance' do
    expect(mux_inheritance_with_exps(name: 'test')).to include(:data)
  end

  it 'options' do
    expect(mux_options_with_exps(name: 'test')).to include(:data)
  end

  # negative

  it 'reconfig:mux_does_not_used' do
    mux_reconfigure_with_exps(name: 'test', code: :mux_does_not_used)
  end
end
