require 'spec_helper'

describe 'Messages' do
  before :each do
    $stdout.stub!(:puts)
    $stdout.stub!(:print)
    $stderr.stub!(:puts)
    Kernel.stub!(:system).with("clear")
  end
  context "#installed_kernels(installed_kernels)" do
    context "when installed_kernels = 0" do
      it "returns 'no kernels found error' message" do
        expect(Messages.installed_kernels([])).
          to match "ERROR: No kernels found in the /boot directory!"
      end
    end

    context "when installed_kernels = 1" do
      it "returns 'only one kernel found' message" do
        expect(Messages.installed_kernels(@installed_kernels.last(1))).
          to match "Only one kernel found!"
      end
    end

    context "when installed_kernels > 1" do
      it "returns 'multiple kernels found' message" do
        expect(Messages.installed_kernels(@installed_kernels)).
          to match "Found #{@installed_kernels.length} kernels installed:"
      end
    end

    it "returns kernels as a string" do
      expect(Messages.installed_kernels(@installed_kernels)).
        to match "  2.4.28-11  \n  3.2.0-8  \n  3.2.0-11  \n"
    end
  end

  context "#other_kernels" do
    context "when other_kernels.length is greater than 0" do
      it "returns 'you have other kernels' message" do
        message = "### NOTE: You have kernels in your /boot directory " +
                  "that have no corresponding packages installed." + "\n"
                  "###       If you know you don't want those kernels, " +
                  "you may want to remove them."

        expect(Messages.other_kernels).to match message
      end

      it "returns list and remove commands" do
        Kernels.stub!(:find_kernels).
          and_return({ :all => @all_kernels, :installed => @installed_kernels })

        [(@all_kernels - @installed_kernels).first, "sudo ls -ahl ", "sudo rm -f "].each do |string|
          expect(Messages.other_kernels).to match string
        end
      end
    end
    
    it "returns nothing if other_kernels.length == 0" do
      Kernels.stub!(:find_kernels).and_return({ :all => @all_kernels, :installed => @all_kernels })
      expect(Messages.other_kernels).to be_empty
    end
  end

  context "#print_purge_packages_success(kernels_to_remove)" do
    it "prints successful purge message" do
      output = capture_stdout { Messages.print_purge_packages_success(@all_kernels.drop(2)) }

      ["Successfully removed the kernel packages for: #{@all_kernels.drop(2).join(', ')}",
      "### NOTE: Usually apt-get will update your bootloader automatically,",
      "###       but if you have any trouble you may need to update it manually."].each do |string|
        expect(output).to match string
      end
    end
  end

  context "#print_purge_packages_failure(exit_code)" do
    it "prints failed purge message" do
      $stderr.should_receive(:puts).with("ERROR: apt-get purge failed with \"12345\"")
      Messages.print_purge_packages_failure("12345")
    end
  end

  context "#confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)" do
    it "prints 'multiple kernels message' when multiple kernels" do
      output = capture_stdout {
        Messages.confirm_kernels_to_be_removed(@installed_kernels.drop(1), @installed_kernels) }

      expect(output).to match "The #{@installed_kernels.drop(1).length
                                     } kernels marked with asterisks will be apt-get purged:"
    end
    it "prints 'singular kernel message' when only one kernel" do
      output = capture_stdout {
        Messages.confirm_kernels_to_be_removed(@installed_kernels.first(1), @installed_kernels) }

      ["The kernel marked with asterisks will be apt-get purged:",
      "Are you sure you want to continue "].each do |string|
        expect(output).to match string
      end
    end
  end

  context "#get_free_disk_space" do
    it "gets available disk space" do
      Kernel.should_receive(:`).with("df -BM /boot").
        and_return("Filesystem     1M-blocks  Used Available Use% Mounted on\n/dev/sdc3         46935M 9115M    35437M  21% /\n")

      Messages.get_free_disk_space
    end
  end
end
