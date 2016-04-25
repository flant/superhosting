describe 'Superhosting::Controller::Site (cli)' do
  include SpecHelpers::Controller::Site
  include SpecHelpers::Controller::Container

  def add_site
    container_add(name: @container_name, model: 'test')
    site_add(name: @site_name, container_name: @container_name)
  end

  def add_alias
    add_site
    site_alias_add(name: "new.#{@site_name}")
  end

  it 'site add' do
    container_add(name: @container_name)
    expect { cli('site', 'add', @site_name, '-c', @container_name) }.to_not raise_error
  end

  it 'site container' do
    add_site
    expect { cli('site', 'container', @site_name) }.to_not raise_error
  end

  it 'site delete' do
    add_site
    expect { cli('site', 'delete', @site_name) }.to_not raise_error
  end

  it 'site inspect' do
    add_site
    expect { cli('site', 'inspect', @site_name) }.to_not raise_error
    expect { cli('site', 'inspect', @site_name, '--inheritance') }.to_not raise_error
    expect { cli('site', 'inspect', @site_name, '--erb') }.to_not raise_error
  end

  it 'site inheritance' do
    add_site
    expect { cli('site', 'inheritance', @site_name) }.to_not raise_error
    expect { cli('site', 'inheritance', @site_name, '--json') }.to_not raise_error
  end

  it 'site options' do
    add_site
    expect { cli('site', 'options', @site_name) }.to_not raise_error
    expect { cli('site', 'options', @site_name, '--inheritance') }.to_not raise_error
    expect { cli('site', 'options', @site_name, '--erb') }.to_not raise_error
  end

  it 'site list' do
    add_site
    expect { cli('site', 'list') }.to_not raise_error
    expect { cli('site', 'list', '-c', @container_name) }.to_not raise_error
    expect { cli('site', 'list', '--state') }.to_not raise_error
    expect { cli('site', 'list', '--json') }.to_not raise_error
  end

  it 'site name' do
    add_site
    expect { cli('site', 'name', @site_name) }.to_not raise_error
  end

  it 'site reconfigure' do
    add_site
    expect { cli('site', 'reconfigure', @site_name) }.to_not raise_error
  end

  it 'site rename' do
    add_site
    expect { cli('site', 'rename', @site_name, '-r', 'testSname.com') }.to_not raise_error
  end

  it 'site move' do
    add_site
    container_add(name: "#{@container_name}2", model: 'test')
    expect { cli('site', 'move', @site_name, '-c', "#{@container_name}2") }.to_not raise_error
  end

  it 'site alias add' do
    add_site
    expect { cli('site', 'alias', 'add', "new.#{@site_name}", '-s', @site_name) }.to_not raise_error
  end

  it 'site alias delete' do
    add_alias
    expect { cli('site', 'alias', 'delete', "new.#{@site_name}", '-s', @site_name) }.to_not raise_error
  end

  it 'site alias list' do
    add_alias
    expect { cli('site', 'alias', 'list', '-s', @site_name) }.to_not raise_error
    expect { cli('site', 'alias', 'list', '-s', @site_name, '--json') }.to_not raise_error
  end
end
