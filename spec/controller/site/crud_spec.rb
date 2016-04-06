require_relative 'spec_helpers'

describe Superhosting::Controller::Site do
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Site

  # positive

  it 'add' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
    end
  end

  it 'name' do
    with_container do |container_name|
      with_site do |site_name|
        expect(site_name_with_exps(name: site_name)[:data]).to eq site_name
      end
    end
  end

  it 'name by alias' do
    with_site_alias do |container_name, site_name, alias_name|
      expect(site_name_with_exps(name: alias_name)[:data]).to eq site_name
    end
  end

  it 'container' do
    with_container do |container_name|
      with_site do |site_name|
        expect(site_container_with_exps(name: site_name)[:data]).to eq container_name
      end
    end
  end

  it 'container by alias' do
    with_site_alias do |container_name, site_name, alias_name|
      expect(site_container_with_exps(name: alias_name)[:data]).to eq container_name
    end
  end

  it 'delete' do
    with_container do |container_name|
      with_site
    end
  end

  it 'delete by alias' do # TODO
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      alias_name = "alias-#{@site_name}"
      site_alias_add_with_exps(name: alias_name)
      site_delete_with_exps(name: alias_name)
    end
  end

  it 'rename' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      new_name = "new.#{@site_name}"
      site_rename_with_exps(name: @site_name, new_name: new_name)
    end
  end

  it 'rename by alias' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      alias_name = "alias-#{@site_name}"
      site_alias_add_with_exps(name: alias_name)
      new_name = "new.#{@site_name}"
      site_rename_with_exps(name: alias_name, new_name: new_name)
    end
  end

  it 'rename alias save name' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      alias_name = "alias-#{@site_name}"
      site_alias_add_with_exps(name: alias_name)
      site_rename_with_exps(name: @site_name, new_name: alias_name, alias_name: true)
      expect_in_file(self.site_aliases(container_name, alias_name), @site_name)
      not_expect_in_file(self.site_aliases(container_name, alias_name), alias_name)
    end
  end

  it 'reconfig' do
    with_container(model: 'bitrix_m') do |container_name|
      with_site do |site_name|
        site_reconfigure_with_exps(name: site_name)
      end
    end
  end

  it 'reconfig by alias' do
    with_site_alias do |container_name, site_name, alias_name|
      site_reconfigure_with_exps(name: alias_name)
    end
  end

  it 'list' do
    with_container do |container_name|
      with_site do |site_name|
        expect(site_list_with_exps(container_name: container_name)[:data].first).to include(:name, :state)
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

  # negative

  INVALID_SITE_NAMES = ['a', '-site.com', 'site.s', 'a.site.ru', 'sub.site.longregion', 'my_site.com']

  it 'add:site_exists' do
    with_container do |container_name|
      site_add_with_exps(name: @site_name, container_name: container_name)
      site_add_with_exps(name: @site_name, container_name: container_name, code: :site_exists)
    end
  end

  it 'add:invalid_site_name' do
    with_container do |container_name|
      INVALID_SITE_NAMES.each {|name| site_add_with_exps(name: name, container_name: container_name, code: :invalid_site_name) }
    end
  end

  it 'add:container_does_not_exists' do
    site_add_with_exps(name: @site_name, container_name: @container_name, code: :container_does_not_exists)
  end

  it 'rename:site_does_not_exists' do
    with_container do |container_name|
      site_rename_with_exps(name: @site_name, new_name: "new.#{@site_name}", code: :site_does_not_exists)
    end
  end

  it 'rename:invalid_site_name' do
    with_container do |container_name|
      with_site do |site_name|
        INVALID_SITE_NAMES.each {|name| site_rename_with_exps(name: site_name, new_name: name, code: :invalid_site_name) }
      end
    end
  end

  it 'rename:site_exists' do
    with_container do |container_name|
      with_site do |site_name|
        site_rename_with_exps(name: site_name, new_name: site_name, code: :site_exists)
      end
    end
  end

  it 'delete:site_does_not_exists' do
    with_container do
      site_delete_with_exps(name: @site_name, code: :site_does_not_exists )
    end
  end

  it 'alias_add:invalid_site_name' do
    with_container do |container_name|
      with_site do |site_name|
        INVALID_SITE_NAMES.each {|name| site_alias_add_with_exps(name: name, code: :invalid_site_name) }
      end
    end
  end

  it 'alias_add:alias_exists' do
    with_container do |container_name|
      with_site do |site_name|
        alias_name = "alias-#{site_name}"
        site_alias_add_with_exps(name: alias_name)
        site_alias_add_with_exps(name: alias_name, code: :alias_exists)
      end
    end
  end

  it 'alias_add:site_exists' do
    with_container do |container_name|
      with_site do |site_name|
        site_alias_add_with_exps(name: site_name, code: :site_exists)
      end
    end
  end

  # other

  it 'add#punycode' do
    with_container do |container_name|
      site_add_with_exps(name: 'домен.рф', container_name: container_name)
      conf_mapper = self.etc.nginx.sites.f("#{container_name}-домен.рф.conf")
      expect_in_file(conf_mapper, 'xn--d1acufc.xn--p1ai')
    end
  end

  it 'recreate' do
    with_container do
      2.times.each { with_site }
    end
  end
end
