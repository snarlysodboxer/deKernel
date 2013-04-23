require 'rubygems'
require 'rspec'

require 'deKernel'
require 'cernel'
require 'message'

RSpec.configure do |c|
  c.before :all do
    @all_kernels = ["2.3.56-1", "2.4.28-11", "3.2.0-8", "3.2.0-11"]
    @installed_kernels = @all_kernels.drop(1)
    @other_kernels = @all_kernels - @installed_kernels
    @remove_kernels = @installed_kernels.drop(1)

    @all_packages = Array.new
    @installed_kernels.each do |kernel|
      ["linux-headers-#{kernel}",
       "linux-headers-#{kernel}-generic",
       "linux-image-#{kernel}-generic"].each do |package|
         @all_packages << package
      end
    end

    @remove_packages = Array.new
    @remove_kernels.each do |kernel|
      ["linux-headers-#{kernel}",
       "linux-headers-#{kernel}-generic",
       "linux-image-#{kernel}-generic"].each do |package|
         @remove_packages << package
      end
    end
  end
end
