describe Superhosting::Cli do
  include SpecHelpers::Base

  it 'sx' do
    expect { cli }.to_not raise_error
  end

  it 'ambigious command' do
    expect_exception_code(code: :ambiguous_command) { cli('m') }
  end

  it 'invalid option' do
    expect_exception_code(code: :invalid_cli_option) { cli('s', 'l', '-a') }
  end
end
