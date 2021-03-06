describe Superhosting::Controller::Container do
  include SpecHelpers::Controller::Admin
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site
  include SpecHelpers::Controller::Mysql

  # positive

  it 'add' do
    container_add_with_exps(name: @container_name, model: 'test')
  end

  it 'delete' do
    with_container
  end

  it 'reconfig' do
    with_container(model: 'test') do |container_name|
      with_site do |_site_name|
        container_reconfigure_with_exps(name: container_name)
      end
    end
  end

  it 'reconfig with model' do
    with_container do |container_name|
      with_site do |_site_name|
        container_reconfigure_with_exps(name: container_name, model: 'test')
      end
    end
  end

  it 'rename' do
    container_add_with_exps(name: @container_name)
    site_add_with_exps(name: @site_name, container_name: @container_name)
    new_name = "new_#{@container_name}"
    container_rename_with_exps(name: @container_name, new_name: new_name)
    site_delete_exps(name: @site_name, container_name: @container_name)
    site_add_exps(name: @site_name, container_name: new_name)
  end

  it 'rename check users' do
    container_add_with_exps(name: @container_name)
    user_add_with_exps(name: @user_name, container_name: @container_name, generate: true)
    admin_add_with_exps(name: @admin_name, generate: true)
    admin_container_add_with_exps(name: @container_name)
    new_name = "new_#{@container_name}"
    container_rename_with_exps(name: @container_name, new_name: new_name)
    user_add_exps(name: @user_name, container_name: new_name)
    admin_container_add_exps(name: new_name)
  end

  it 'rename check mysql dbs / users' do
    container_add_with_exps(name: @container_name)
    [@mysql_user_name, "#{@mysql_user_name}2"].each do |user_name|
      mysql_user_add_with_exps(name: user_name, container_name: @container_name, generate: true)
    end
    mysql_db_add_with_exps(name: @mysql_db_name, container_name: @container_name, users: [@mysql_user_name])
    new_name = "n#{@container_name}"
    container_rename_with_exps(name: @container_name, new_name: new_name)
    [@mysql_user_name, "#{@mysql_user_name}2"].each do |user_name|
      mysql_user_add_exps(name: "#{new_name}_#{user_name}")
    end
    mysql_db_add_exps(name: @mysql_db_name, container_name: new_name)
  end

  it 'update', :docker do
    begin
      with_container(model: 'test') do |container_name|
        expect(docker_api.container_image?(@container_name, 'sx-base')).to be_truthy
        command!('docker tag -f sx-almost-base superhosting/test')
        container_update_with_exps(name: container_name)
        expect(docker_api.container_image?(@container_name, 'sx-base')).to be_falsey
        expect(docker_api.container_image?(@container_name, 'sx-almost-base')).to be_truthy
      end
    ensure
      command!('docker tag -f sx-base superhosting/test')
    end
  end

  it 'list' do
    with_container do |_container_name|
      expect(container_list_with_exps[:data].first).to include('name', 'state')
    end
  end

  it 'inspect' do
    with_container do |container_name|
      expect(container_inspect_with_exps(name: container_name)[:data]).to include('name', 'state', 'model', 'options', 'users')
    end
  end

  it 'inheritance' do
    with_container do |container_name|
      expect(container_inheritance_with_exps(name: container_name)).to include(:data)
    end
  end

  it 'options' do
    with_container do |container_name|
      expect(container_options_with_exps(name: container_name)).to include(:data)
    end
  end

  it 'model name' do
    with_container(model: 'test') do |container_name|
      expect(container_model_name_with_exps(name: container_name)[:data]).to eq 'test'
    end
  end

  it 'model tree' do
    with_container(model: 'test') do |container_name|
      expect(container_model_tree_with_exps(name: container_name)).to include(:data)
    end
  end

  it 'admin_add' do
    with_admin do |admin_name|
      with_container do |_container_name|
        container_admin_add_with_exps(name: admin_name)
      end
    end
  end

  it 'admin_delete' do
    with_container_admin
  end

  it 'admin_list' do
    with_container_admin do |container_name, admin_name|
      expect(container_admin_list_with_exps[:data]).to include('admin' => admin_name, 'user' => "#{container_name}_admin_#{admin_name}")
    end
  end

  # negative

  it 'add:container_exists' do
    container_add_with_exps(name: @container_name)
    container_add_with_exps(name: @container_name, model: :incorrect_model_name, code: :container_exists)
  end

  it 'add:invalid_container_name' do
    invalid_names = [:s, :'!incorrectsymbol']
    invalid_names.each { |name| container_add_with_exps(name: name, code: :invalid_container_name) }
  end

  it 'add:invalid_container_name_by_user_format' do
    container_add_with_exps(name: '123asd', code: :invalid_container_name_by_user_format)
  end

  it 'add:model_does_not_exists' do
    container_add_with_exps(name: @container_name, model: :incorrect_model_name, code: :model_does_not_exists)
  end

  xit 'add:bad_value_of_docker_option' do # TODO
  end

  it 'rename:no_model_given' do
    container_add_with_exps(name: @container_name)
    begin
      default_model_mapper = config.default_model
      default_model = default_model_mapper.value
      default_model_mapper.delete!

      new_name = "new_#{@container_name}"
      container_rename_with_exps(name: @container_name, new_name: new_name, code: :no_model_given)
    ensure
      default_model_mapper.put!(default_model)
    end
  end

  it 'rename:container_does_not_exists' do
    container_rename_with_exps(name: @container_name, new_name: 'new_name', code: :container_does_not_exists)
  end

  it 'reconfig:container_does_not_exists' do
    container_reconfigure_with_exps(name: @container_name, code: :container_does_not_exists)
  end

  it 'delete:container_does_not_exists' do
    container_delete_with_exps(name: @container_name, code: :container_does_not_exists)
  end

  it 'admin_add:admin_does_not_exists' do
    with_container do |_container_name|
      container_admin_add_with_exps(name: @admin_name, code: :admin_does_not_exists)
    end
  end

  it 'admin_delete:admin_does_not_exists' do
    with_container do |_container_name|
      container_admin_add_with_exps(name: 'incorrect_admin_name', code: :admin_does_not_exists)
    end
  end

  it 'add:no_docker_image_specified_in_model_or_mux' do
    begin
      image_mapper = config.models.test.container.docker.image
      image = image_mapper.value
      image_mapper.delete!
      container_add_with_exps(name: @container_name, model: 'test', code: :no_docker_image_specified_in_model_or_mux)
    ensure
      image_mapper.put!(image)
    end
  end

  it 'add:docker_command_not_found' do
    begin
      command_mapper = config.models.test.container.docker.command
      command = command_mapper.value
      command_mapper.delete!
      container_add_with_exps(name: @container_name, model: 'test', code: :docker_command_not_found)
    ensure
      command_mapper.put!(command)
    end
  end

  # other

  it 'add#mux', :docker do
    with_container(model: 'test_with_mux') do
      expect(docker_api.container_running?('mux-test')).to be_truthy
      with_container(name: "#{@container_name}2", model: 'test_with_mux')
      expect(docker_api.container_running?('mux-test')).to be_truthy
    end
    expect(docker_api.container_running?('mux-test')).to be_falsey
  end

  it 'reconfig@stop_mux', :docker do
    with_container(model: 'test_with_mux') do |container_name|
      expect(docker_api.container_running?('mux-test')).to be_truthy
      container_reconfigure_with_exps(name: container_name, model: 'test')
      expect(docker_api.container_running?('mux-test')).to be_falsey
    end
  end

  it 'reconfig@up_docker', :docker do
    def up_docker(name)
      expect(docker_api.container_running?(name)).to be_falsey
      container_reconfigure_with_exps(name: name)
      expect(docker_api.container_running?(name)).to be_truthy
    end

    with_container(model: 'test') do |container_name|
      docker_api.container_stop!(container_name)
      up_docker(container_name)

      docker_api.container_kill!(container_name)
      up_docker(container_name)

      docker_api.container_pause!(container_name)
      up_docker(container_name)

      docker_api.container_kill!(container_name)
      docker_api.container_rm!(container_name)
      expect(docker_api.container_exists?(container_name)).to be_falsey
      container_reconfigure_with_exps(name: container_name)
      expect(docker_api.container_running?(container_name)).to be_truthy
    end
  end

  it 'reconfig@system_users' do
    with_container(model: 'fcgi_m') do |container_name|
      config.containers.f(container_name).system_users.put!('test_system_user')
      container_reconfigure_with_exps(name: container_name)
      user_delete_exps(name: 'fcgi', container_name: container_name)
      user_add_exps(name: 'test_system_user', container_name: container_name, shell: '/usr/sbin/nologin')
    end
  end

  it 'reconfig@signature', :docker do
    with_container(model: 'test') do |container_name|
      signature_path = container_lib(container_name).signature.path
      expect_file_mtime signature_path do
        begin
          memory_mapper = config.models.test.container.docker.memory
          memory = memory_mapper.value
          memory_mapper.delete!

          container_reconfigure_with_exps(name: container_name)
        ensure
          memory_mapper.put!(memory)
        end
      end
    end
  end

  it 'reconfig@config.rb', :docker do
    with_container(model: 'test') do |container_name|
      with_site do |site_name|
        registry_mapper = container_lib(container_name).registry
        expect_file_mtime registry_mapper.container.path, registry_mapper.sites.f(site_name).path do
          begin
            (container_config_rb_mapper = config.models.test.container.f('config.rb')).append_line!('mkdir "#{container.web.path}/logs/test"')
            (site_config_rb_mapper = config.models.test.site.f('config.rb')).append_line!('mkdir "#{site.web.path}/logs/test"')
            container_reconfigure_with_exps(name: container_name)
            expect_dir("/web/#{container_name}/logs/test")
            expect_dir("/web/#{container_name}/#{site_name}/logs/test")
          ensure
            container_config_rb_mapper.remove_line!('mkdir "#{container.web.path}/logs/test"')
            site_config_rb_mapper.remove_line!('mkdir "#{site.web.path}/logs/test"')
          end
        end
      end
    end
  end

  it 'add@override_image_by_mux', :docker do
    test_image = config.models.test.container.docker.image.value
    mux_image = config.muxs.test.container.docker.image.value
    container_add_with_exps(name: @container_name, model: 'test_with_mux')
    expect(docker_api.container_image?(@container_name, test_image)).to be_falsey
    expect(docker_api.container_image?(@container_name, mux_image)).to be_truthy
  end

  it 'add@default_databases' do
    begin
      default_databases_mapper = config.models.test.container.default_databases
      value = default_databases_mapper.value
      default_databases_mapper.put!('test_database')

      container_add_with_exps(name: @container_name, model: 'test')
      expect(mysql_container_dbs_index(@container_name)).to include("#{@container_name}_test_database")
    ensure
      if value.nil?
        default_databases_mapper.delete!
      else
        default_databases_mapper.put!(value)
      end
    end
  end

  it 'recreate@container' do
    2.times.each { with_container }
  end

  it 'recreate@container_admin' do
    2.times.each { with_container_admin }
  end
end
