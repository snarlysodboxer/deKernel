require 'rubygems'
require 'rspec'

require 'dekernel'
require 'dekernel/cernel'
require 'dekernel/message'

RSpec.configure do |c|
  c.before :all do
    $options = { :dry_run => false, :assume_yes => false, :kernels_list => nil,
                 :all_except => nil, :no_confirm => false }

    @all_kernels = ["2.3.56-1", "2.4.28-11", "3.2.0-11", "3.2.0-8"]
    @installed_kernels = @all_kernels.drop(1)
    @all_except_latest_one = @installed_kernels - ["3.2.0-11"]
    @kernels_hash = { :all => @all_kernels, :installed => @installed_kernels }
    @other_kernels = @all_kernels - @installed_kernels
    @remove_kernels = @installed_kernels.drop(1)

    @remove_packages = @remove_kernels.collect { |kernel|
      ["linux-headers-#{kernel}",
       "linux-headers-#{kernel}-generic",
       "linux-image-#{kernel}-generic"]
    }.flatten

  end
end

