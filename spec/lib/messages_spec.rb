require 'spec_helper'

describe 'Messages' do
  context "#print_installed_kernels(installed_kernels)" do
    context "when installed_kernels = 0" do
      it "raises SystemExit" do
        expect(lambda { Messages.print_installed_kernels([]) }).
          to raise_error SystemExit
      end

      it "prints 'no kernels found error' message" do
        Kernel.stub!(:exit)
        Kernels.stub!(:find_all_kernels).and_return([])
        $stderr.should_receive(:puts).with("ERROR: No kernels found in the /boot directory!")
        Messages.print_installed_kernels([])
      end
    end

    context "when installed_kernels = 1" do
      it "prints 'only one kernel found' message" do
        output = capture_stdout { Messages.print_installed_kernels(@installed_kernels.last(1)) }

        expect(output).to match "Only one kernel found!"
      end
    end

    context "when installed_kernels > 1" do
      it "prints 'multiple kernels found' message" do
        output = capture_stdout { Messages.print_installed_kernels(@installed_kernels) }

        expect(output).to match "Found #{@installed_kernels.length} kernels installed:"
      end
    end

    it "prints kernels" do
      output = capture_stdout { Messages.print_installed_kernels(@installed_kernels) }

      @installed_kernels.each do |kernel|
        expect(output).to match kernel
      end
    end
  end

  context "#print_other_kernels" do
    context "when other_kernels.length is greater than 0" do
      before :each do
        Kernels.stub!(:find_kernels).
          and_return({ :all => @all_kernels, :installed => @installed_kernels })
        @output = capture_stdout { Messages.print_other_kernels }
      end
      it "should print 'you have other kernels' message" do
        ["### NOTE: You have kernels in your /boot directory that have no corresponding packages installed.",
        "###       If you know you don't want those kernels, you may want to remove them."].each do |message|
          expect(@output).to match message
        end
      end

      it "should print list and remove commands" do
        [(@all_kernels - @installed_kernels).first, "sudo ls -ahl ", "sudo rm -f "].each do |string|
          expect(@output).to match string
        end
      end
    end
    
    it "should print nothing if other_kernels.length == 0" do
      Kernels.stub!(:find_kernels).
        and_return({ :all => @installed_kernels, :installed => @installed_kernels })
      output = capture_stdout { Messages.print_other_kernels }

      expect(output.to_s).to be_empty
    end
  end

  context "#print_purge_packages_success(kernels_to_remove)" do
    it "should print successful purge message" do
      output = capture_stdout { Messages.print_purge_packages_success(@all_kernels.drop(2)) }

      ["Successfully removed the kernel packages for: #{@all_kernels.drop(2).join(', ')}",
      "### NOTE: Now you will want to update your bootloader."].each do |string|
        expect(output).to match string
      end
    end
  end

  context "#print_purge_packages_failure(exit_code)" do
    it "should print failed purge message" do
      $stderr.should_receive(:puts).with("ERROR: apt-get purge failed with exit code 12345")
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
end
