require_relative 'spec_helpers'

describe Superhosting::Controller::Site do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  it 'add' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
    end
  end

  it 'delete' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      site_delete_with_exps(name: @site_name)
    end
  end

  it 'rename' do
    with_container do |container_name|
      with_site do |site_name|
        new_name = "new.#{site_name}"
        site_rename_with_exps(name: site_name, new_name: new_name)
      end
    end
  end

  it 'alias_add' do
    with_container do |container_name|
      with_site do |site_name|
        alias_name = "alias-#{site_name}"
        site_alias_add_with_exps(name: alias_name)
      end
    end
  end

  it 'alias_delete' do
    with_container do |container_name|
      with_site do |site_name|
        alias_name = "alias-#{site_name}"
        site_alias_add_with_exps(name: alias_name)
        site_alias_delete_with_exps(name: alias_name)
      end
    end
  end
end
