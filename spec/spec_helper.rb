require 'rubygems'
require 'rspec'

require 'deKernel'
require 'kernels'
require 'messages'

RSpec.configure do |c|
  c.before :all do
    @all_kernels = ["2.4.28-11", "3.2.0-8", "3.2.0-11"]
    @installed_kernels = @all_kernels.drop(1)
  end

  def capture_stout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
  end
end
