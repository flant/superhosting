describe 'Superhosting::Controller::Mysql (cli)' do
  include SpecHelpers::Controller::Mysql
  include SpecHelpers::Controller::Container

  def add_mysql_user
    container_add_with_exps(name: @container_name)
    mysql_user_add_with_exps(name: "#{@container_name}_#{@mysql_user_name}", generate: true)
  end

  def add_mysql_db
    container_add_with_exps(name: @container_name)
    mysql_db_add_with_exps(name: "#{@container_name}_#{@mysql_db_name}")
  end

  it 'mysql user add' do
    with_container do |container_name|
      expect { cli('mysql', 'user', 'add', "#{container_name}_#{@mysql_user_name}", '-g') }.to_not raise_error
    end
  end

  it 'mysql user add with -c' do
    with_container do |container_name|
      expect { cli('mysql', 'user', 'add', 'test', '-c', container_name, '-g') }.to_not raise_error
    end
  end

  it 'mysql user del' do
    add_mysql_user
    expect { cli('mysql', 'user', 'delete', "#{@container_name}_#{@mysql_user_name}") }.to_not raise_error
  end

  it 'mysql user list' do
    add_mysql_user
    expect { cli('mysql', 'user', 'list') }.to_not raise_error
    expect { cli('mysql', 'user', 'list', '--json') }.to_not raise_error
    expect { cli('mysql', 'user', 'list', '-c', @container_name) }.to_not raise_error
  end

  it 'mysql user inspect' do
    add_mysql_user
    expect { cli('mysql', 'user', 'inspect') }.to_not raise_error
  end

  it 'mysql db add' do
    with_container do |container_name|
      expect { cli('mysql', 'db', 'add', "#{container_name}_#{@mysql_db_name}") }.to_not raise_error
    end
  end

  it 'mysql db add with -c' do
    with_container do |container_name|
      expect { cli('mysql', 'db', 'add', "#{@mysql_db_name}", '-c', container_name) }.to_not raise_error
    end
  end

  it 'mysql db delete' do
    add_mysql_db
    expect { cli('mysql', 'db', 'delete', "#{@container_name}_#{@mysql_db_name}") }.to_not raise_error
  end

  it 'mysql db list' do
    add_mysql_db
    expect { cli('mysql', 'db', 'list') }.to_not raise_error
    expect { cli('mysql', 'db', 'list', '--json') }.to_not raise_error
    expect { cli('mysql', 'db', 'list', '-c', @container_name) }.to_not raise_error
  end

  it 'mysql db inspect' do
    add_mysql_db
    expect { cli('mysql', 'db', 'inspect', "#{@container_name}_#{@mysql_db_name}") }.to_not raise_error
  end
end
