require 'rubygems'
require 'rspec'

require 'deKernel'
require 'cernel'
require 'message'

RSpec.configure do |c|
  c.before :all do
    $options = { dry_run: false }

    @all_kernels = ["2.3.56-1", "2.4.28-11", "3.2.0-8", "3.2.0-11"]
    @installed_kernels = @all_kernels.drop(1)
    @other_kernels = @all_kernels - @installed_kernels
    @remove_kernels = @installed_kernels.drop(1)

    @remove_packages = @remove_kernels.collect { |kernel|
      ["linux-headers-#{kernel}",
       "linux-headers-#{kernel}-generic",
       "linux-image-#{kernel}-generic"]
    }.flatten
  end
end
