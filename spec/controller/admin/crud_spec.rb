describe Superhosting::Controller::Admin do
  include SpecHelpers::Controller::User
  include SpecHelpers::Controller::Container
  include SpecHelpers::Controller::Admin

  # positive

  it 'add' do
    expect(admin_add_with_exps(name: @admin_name, generate: true)).to include(:data)
  end

  it 'delete' do
    with_admin
  end

  it 'passwd' do
    with_admin do |admin_name|
      expect(admin_passwd_with_exps(name: admin_name, generate: true)).to include(:data)
    end
  end

  it 'list' do
    with_container do |container_name|
      with_admin do |admin_name|
        admin_container_add_with_exps(name: container_name)
        expect(admin_list_with_exps[:data]).to include({ admin_name => [{ 'container' => container_name, 'user' => "#{container_name}_admin_#{admin_name}"}] })
      end
    end
  end

  it 'container_add' do
    with_container do |container_name|
      with_admin do |admin_name|
        admin_container_add_with_exps(name: container_name)
      end
    end
  end

  it 'container_delete' do
    with_admin_container
  end

  it 'container_list' do
    with_admin_container do |container_name, admin_name|
      expect(admin_container_list_with_exps[:data]).to include('container' => container_name, 'user' => "#{container_name}_admin_#{admin_name}")
    end
  end

  # negative

  it 'add:admin_exists' do
    admin_add_with_exps(name: @admin_name, generate: true)
    admin_add_with_exps(name: @admin_name, generate: true, code: :admin_exists)
  end

  it 'delete:admin_does_not_exists' do
    admin_container_delete_with_exps(name: @admin_name, code: :admin_does_not_exists)
  end

  it 'passwd:admin_does_not_exists' do
    admin_passwd_with_exps(name: @admin_name, generate: true, code: :admin_does_not_exists)
  end

  it 'container_add:container_does_not_exists' do
    with_admin do |admin_name|
      admin_container_add_with_exps(name: @container_name, code: :container_does_not_exists)
    end
  end

  it 'container_add:user_exists' do
    with_container do |container_name|
      with_admin do |admin_name|
        admin_container_add_with_exps(name: container_name)
        admin_container_add_with_exps(name: container_name, code: :user_exists)
      end
    end
  end

  it 'container_delete:container_does_not_exists' do
    with_admin do |admin_name|
      admin_container_delete_with_exps(name: @container_name, code: :container_does_not_exists)
    end
  end

  it 'container_delete:admin_does_not_exists' do
    admin_container_delete_with_exps(name: @admin_name, code: :admin_does_not_exists)
  end

  # other

  it 'recreate admin' do
    2.times.each { with_admin }
  end

  it 'recreate admin container' do
    2.times.each { with_admin_container }
  end
end
