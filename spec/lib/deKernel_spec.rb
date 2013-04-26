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
    before :each do
      $options[:all_except] = 1
      $options[:kernels_list] = @remove_kernels.join(" ")

      Cernel.should_receive(:find_all_kernels).and_return(@all_kernels)
      Cernel.should_receive(:find_installed_kernels).with(@all_kernels).and_return(@installed_kernels)

      @kernels_to_remove = @remove_kernels.sort.reverse
      @kernels_to_remove.shift($options[:all_except].to_i)
      Cernel.should_receive(:find_kernel_packages).with(@kernels_to_remove).and_return(@remove_packages)
    end

    it  "removes all except latest (n)" do
      Cernel.should_receive(:purge_packages_from_a_list_of_kernels).with(@kernels_to_remove)

      DeKernel.run
    end

    it "calls confirm_removals" do
      Cernel.should_receive(:purge_packages_from_a_list_of_kernels).with(@kernels_to_remove)
      #Cernel.should_receive(:confirm_removals).with(@kernels_to_remove)
      Cernel.should_receive(:confirm_removals)

      DeKernel.run
    end

    it "should not receive 'ask which' or 'purge packages with all' methods" do
      Cernel.should_not_receive(:ask_which_to_remove)
      Cernel.should_not_receive(:purge_packages_from_a_list_of_kernels).with($options[:kernels_list].split(" "))

      DeKernel.run
    end
  end
end
