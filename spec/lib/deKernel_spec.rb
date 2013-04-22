require 'spec_helper'

describe 'deKernel' do
  before :each do
    $stdout.stub!(:puts)
    Messages.stub!(:other_kernels)
    Kernel.stub!(:system).with("clear")
    Kernels.stub!(:ask_which_to_remove)
    Kernels.stub!(:purge_packages_from_a_list_of_kernels)
  end

  it "prints 'generally recommended' message" do
    $stdout.should_receive(:puts).
      with("It's generally recommended to leave at least three of your latest kernels installed.")
    DeKernel.run
  end

  it "calls Kernels.purge_packages_from_a_list_of_kernels(Kernels.ask_which_to_remove)" do
    Kernels.should_receive(:ask_which_to_remove)
    Kernels.should_receive(:purge_packages_from_a_list_of_kernels)
    DeKernel.run
  end

  it "prints Messages.other_kernels" do
    $stdout.should_receive(:puts)
    Messages.should_receive(:other_kernels)
    DeKernel.run
  end

  it "prints 'disk space freed' message" do
    $stdout.should_receive(:puts).with("0 megabytes of disk space were freed.")
    DeKernel.run
  end
end
