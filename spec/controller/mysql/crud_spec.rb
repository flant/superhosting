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
    with_mysql_db do |database_name|
      mysql_user_add_with_exps(name: @mysql_user_name, container_name: @container_name, databases: [database_name], generate: true)
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

  # negative

  it 'add:container_name_is_not_specified' do
    mysql_user_add_with_exps(name: "#{@container_name}_#{@mysql_user_name}", generate: true, code: :container_name_is_not_specified)
  end
end
