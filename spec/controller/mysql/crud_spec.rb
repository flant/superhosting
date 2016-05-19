describe Superhosting::Controller::Mysql do
  include SpecHelpers::Controller::Mysql
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'user add' do
    with_container do |container_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, generate: true)
    end
  end

  it 'user add with -c' do
    with_container do |container_name|
      mysql_user_add_with_exps(name: "#{container_name}_#{@mysql_user_name}", generate: true)
    end
  end

  it 'user add with database' do
    with_mysql_db do |container_name, database_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, databases: [database_name], generate: true)
    end
  end

  it 'user delete' do
    with_container do |container_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, generate: true)
      mysql_user_delete_with_exps(name: "#{container_name}_#{@mysql_user_name}")
    end
  end

  it 'user list' do
    with_container do |container_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, generate: true)
      expect(mysql_user_list_with_exps[:data].first).to include('name', 'grants')
    end
  end

  it 'user inspect' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_user_name, container_name: container_name, generate: true)
      expect(mysql_db_inspect_with_exps(name: "#{container_name}_#{@mysql_user_name}")[:data]).to include('name', 'grants')
    end
  end

  it 'user delete with database' do # TODO
    with_mysql_db do |container_name, database_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, databases: [database_name], generate: true)
      mysql_user_delete_with_exps(name: "#{container_name}_#{@mysql_user_name}")
    end
  end

  it 'db add' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_db_name, container_name: container_name)
    end
  end

  it 'db add with -c' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: "#{container_name}_#{@mysql_db_name}")
    end
  end

  it 'db add with users' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_db_name, container_name: container_name, users: [@mysql_user_name], generate: true)
    end
  end

  it 'db delete' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: "#{container_name}_#{@mysql_db_name}")
      mysql_db_delete_with_exps(name: "#{container_name}_#{@mysql_db_name}")
    end
  end

  it 'db delete with users' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_db_name, container_name: container_name, users: [@mysql_user_name], generate: true)
      mysql_db_delete_with_exps(name: "#{container_name}_#{@mysql_db_name}")
    end
  end

  it 'db list' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_db_name, container_name: container_name)
      expect(mysql_db_list_with_exps[:data].first).to include('name', 'grants')
    end
  end

  it 'db inspect' do
    with_container do |container_name|
      mysql_db_add_with_exps(name: @mysql_db_name, container_name: container_name)
      expect(mysql_db_inspect_with_exps(name: "#{container_name}_#{@mysql_db_name}")[:data]).to include('name', 'grants')
    end
  end

  # negative

  it 'add:container_name_is_not_specified' do
    mysql_user_add_with_exps(name: "#{@container_name}_#{@mysql_user_name}", generate: true, code: :container_name_is_not_specified)
  end

  it 'user add with database:mysql_db_does_not_exists' do
    with_container do |container_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: container_name, databases: [@mysql_db_name], generate: true, code: :mysql_db_does_not_exists)
    end
  end

  it 'user add:invalid_mysql_user_name' do
    with_container do |container_name|
      ["#{container_name}_#{?a*(15-container_name.length)}"].each {|user_name| mysql_user_add_with_exps(name: user_name, code: :invalid_mysql_user_name, generate: true) }
    end
  end
end
