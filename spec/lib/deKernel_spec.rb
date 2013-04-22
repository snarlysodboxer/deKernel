require 'spec_helper'

describe 'deKernel' do
  before :each do
    $stdout.stub!(:puts)
    Message.stub!(:other_kernels)
    Kernel.stub!(:system).with("clear")
    Cernel.stub!(:ask_which_to_remove)
    Cernel.stub!(:purge_packages_from_a_list_of_kernels)
  end

  it "prints 'generally recommended' message" do
    $stdout.should_receive(:puts).
      with("It's generally recommended to leave at least three of your latest kernels installed.")
    DeKernel.run
  end

  it "calls Cernel.purge_packages_from_a_list_of_kernels(Cernel.ask_which_to_remove)" do
    Cernel.should_receive(:ask_which_to_remove)
    Cernel.should_receive(:purge_packages_from_a_list_of_kernels)
    DeKernel.run
  end

  it "prints Message.other_kernels" do
    $stdout.should_receive(:puts)
    Message.should_receive(:other_kernels)
    DeKernel.run
  end

  it "prints 'disk space freed' message" do
    $stdout.should_receive(:puts).with("0 megabytes of disk space were freed.")
    DeKernel.run
  end
end
