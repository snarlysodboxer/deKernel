require 'spec_helper'

describe 'deKernel' do
  before :each do
    $stdout.stub!(:puts)
    message_class = Message.new
    message_class.stub!(:other_kernels)
    Kernel.stub!(:system).with("clear")
    @cernel_class = Cernel.new
    @cernel_class.stub!(:get_free_disk_space).and_return(12345)
    @cernel_class.stub!(:ask_which_to_remove)
    @cernel_class.stub!(:purge_packages_from_a_list_of_kernels)
  end

  it "prints 'generally recommended' message" do
    $stdout.should_receive(:puts).
      with("It's generally recommended to leave at least three of your latest kernels installed.\n\n")
    DeKernel.new.run
  end

  it "calls Cernel.purge_packages_from_a_list_of_kernels(Cernel.ask_which_to_remove)" do
    @cernel_class.should_receive(:ask_which_to_remove)
    @cernel_class.should_receive(:purge_packages_from_a_list_of_kernels)
    DeKernel.new.run
  end

  it "prints Message.other_kernels" do
    $stdout.should_receive(:puts)
    message_class.should_receive(:other_kernels)
    DeKernel.new.run
  end

  it "prints 'disk space freed' message" do
    $stdout.should_receive(:puts).with("0 megabytes of disk space were freed.")
    DeKernel.new.run
  end

  it "accepts a list of kernels to remove" do
    $options[:kernels_list] = @remove_kernels.join(" ")
    @cernel_class.should_not_receive(:ask_which_to_remove)
    @cernel_class.should_receive(:purge_packages_from_a_list_of_kernels).with(@remove_kernels)

    DeKernel.new.run
  end

  context "accepts 'all-except (n)' kernels" do
    it "removes all except latest (n)" do
      $options[:all_except] = 1
      $options[:kernels_list] = @remove_kernels.join(" ")
      @cernel_class.should_not_receive(:ask_which_to_remove)
      @cernel_class.should_not_receive(:purge_packages_from_a_list_of_kernels).with($options[:kernels_list].split(" "))
      @cernel_class.should_receive(:find_all_except_latest).with(1)
      @cernel_class.should_receive(:purge_packages_from_a_list_of_kernels)

      DeKernel.new.run
    end
  end
end
