require 'spec_helper'

describe 'Kernels' do
  context "#find_kernels"
  context "#ask_which_to_remove"

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
          output = capture_stout { Kernels.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1)) }
          expect(output).to match "Packages are being uninstalled, please stand by..."
        end
      end

      it "runs `apt-get -y` command" do
        Kernel.should_receive(:`).with("sudo apt-get purge -y package1package2")
        Kernels.stub!(:find_kernel_packages).and_return("package1 package2")
        Kernels.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1))
      end
    end
  end

  # private methods, test them or not?
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

