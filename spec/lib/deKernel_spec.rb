require 'spec_helper'

describe 'deKernel' do
  before :each do
    $stdout.stub!(:puts)
    Message.stub!(:other_kernels)
    Kernel.stub!(:system).with("clear")
    Cernel.stub!(:get_free_disk_space).and_return(12345)
    Cernel.stub!(:ask_which_to_remove)
    Cernel.stub!(:purge_packages_from_a_list_of_kernels)
  end

  it "prints 'generally recommended' message" do
    $stdout.should_receive(:puts).
      with("It's generally recommended to leave at least three of your latest kernels installed.\n\n")
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

  it "accepts a list of kernels to remove" do
    $options[:kernels_list] = @remove_kernels.join(" ")
    Cernel.should_not_receive(:ask_which_to_remove)
    Cernel.should_receive(:purge_packages_from_a_list_of_kernels).with(@remove_kernels)

    DeKernel.run
  end

  context "accepts 'all-except (n)' kernels" do
    it "removes all except latest (n)" do
      $options[:all_except] = 1
      $options[:kernels_list] = @remove_kernels.join(" ")
      Cernel.should_not_receive(:ask_which_to_remove)
      Cernel.should_not_receive(:purge_packages_from_a_list_of_kernels).with($options[:kernels_list].split(" "))
      Cernel.should_receive(:find_all_except_latest).with(1)
      Cernel.should_receive(:purge_packages_from_a_list_of_kernels)

      DeKernel.run
    end
  end
end

