require 'spec_helper'

describe 'Kernels' do
  before :each do
    $stdout.stub!(:puts)
    $stdout.stub!(:print)
    $stderr.stub!(:puts)
    IO.stub!(:popen)
    Kernel.stub!(:system)
  end
  context "#find_kernels" do
    it "finds all kernels" do
      Kernels.stub!(:find_all_kernels).and_return(@all_kernels)
      kernels = Kernels.find_kernels
      expect(kernels[:all]).to eq @all_kernels
    end

    it "finds installed kernels" do
      Kernels.stub!(:find_installed_kernels).and_return(@installed_kernels)
      kernels = Kernels.find_kernels
      expect(kernels[:installed]).to eq @installed_kernels
    end
  end

  context "#ask_which_to_remove" do
    it "prints each one and adds to list" do
      Kernels.stub!(:find_installed_kernels).and_return(@installed_kernels)
      ARGF.stub!(:first).and_return("y")

      Kernels.ask_which_to_remove
    end

    it "calls 'Messages.print_installed_kernels(installed_kernels)'" do
      Kernel.stub!(:exit)
      Kernels.stub!(:find_kernels).and_return({ :all => @all_kernels, :installed => @installed_kernels })
      Messages.should_receive(:print_installed_kernels).with(@installed_kernels)
      ARGF.stub!(:first).and_return("y")

      Kernels.ask_which_to_remove
    end
  end

  context "#purge_packages_from_a_list_of_kernels(kernels_to_remove)" do
    context "when kernels_to_remove.length is 0" do
      it "raises SystemExit" do
        expect(lambda do
          Kernels.purge_packages_from_a_list_of_kernels([])
        end).to raise_error SystemExit
      end

      it "prints 'no packages error' message" do
        Kernel.stub!(:exit)
        $stderr.should_receive(:puts).with("ERROR: No packages to remove.")
        Kernels.purge_packages_from_a_list_of_kernels([])
      end
    end

    context "when kernels_to_remove.length is > 0" do
      context "when packages found" do
        it "prints 'packages being uninstalled' message" do
          Kernels.stub!(:find_kernel_packages).and_return("package1 package2")
          #$stdout.should_receive(:puts).with("Packages are being uninstalled, please stand by...") ## couldn't get this work, why?
          output = capture_stdout { Kernels.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1)) }
          expect(output).to match "Packages are being uninstalled, please stand by..."
        end

        it "runs `apt-get purge -y` command" do
          IO.should_receive(:popen).with("sudo apt-get purge -y package1 package2")
          Kernels.stub!(:find_kernel_packages).and_return("package1 package2")
          Kernels.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1))
        end
      end
    end
  end


  ### private methods, test them or not?

  #   find_all_kernels
  #   find_installed_kernels(all_kernels)
  #   create_kernels_to_remove_list(installed_kernels)
  #   find_kernel_packages(kernels_to_remove)

  context "#confirm_removals(kernels_to_remove, installed_kernels)" do
    context "when kernels_to_remove.length is 0" do
      it "raises SystemExit" do
        expect(lambda do
          Kernels.send(:confirm_removals, @installed_kernels.first(0), @installed_kernels)
        end).to raise_error SystemExit
      end

      it "prints 'no kernels selected' message" do
        Kernel.stub!(:exit)
        $stderr.should_receive(:puts).with("No kernels selected!")
        Kernels.send(:confirm_removals, @installed_kernels.first(0), @installed_kernels)
      end
    end
  end
end
