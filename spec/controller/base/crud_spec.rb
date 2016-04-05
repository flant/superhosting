require_relative 'spec_helpers'

describe Superhosting::Controller::Base do
  include SpecHelpers::Controller::Base

  # positive

  it 'repair' do
    base_repair_with_exps
  end
end
