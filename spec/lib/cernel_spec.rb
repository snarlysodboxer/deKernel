require 'spec_helper'

describe 'Cernel' do
  before :each do
    $stdout.stub!(:puts)
    $stdout.stub!(:print)
    $stderr.stub!(:puts)
    IO.stub!(:popen)
    Kernel.stub!(:system)
  end
  context "#find_kernels" do
    it "finds all kernels" do
      Cernel.stub!(:find_all_kernels).and_return(@all_kernels)
      kernels = Cernel.find_kernels
      expect(kernels[:all]).to eq @all_kernels
    end

    it "finds installed kernels" do
      Cernel.stub!(:find_installed_kernels).and_return(@installed_kernels)
      kernels = Cernel.find_kernels
      expect(kernels[:installed]).to eq @installed_kernels
    end
  end

  context "#ask_which_to_remove" do
    it "raises SystemExit if installed_kernels.length == 0" do
      Cernel.stub!(:find_kernels).and_return({ :installed => [] })
      expect(lambda { Cernel.ask_which_to_remove }).
        to raise_error SystemExit
    end

    it "prints each one and adds to list" do
      Cernel.stub!(:find_installed_kernels).and_return(@installed_kernels)
      ARGF.stub!(:first).and_return("y")

      Cernel.ask_which_to_remove
    end

    it "calls 'Message.installed_kernels(installed_kernels)'" do
      Kernel.stub!(:exit)
      Cernel.stub!(:find_kernels).and_return({ :all => @all_kernels, :installed => @installed_kernels })
      Message.should_receive(:installed_kernels).with(@installed_kernels)
      ARGF.stub!(:first).and_return("y")

      Cernel.ask_which_to_remove
    end
  end

  context "#purge_packages_from_a_list_of_kernels(kernels_to_remove)" do
    context "when kernels_to_remove.length is 0" do
      it "raises SystemExit" do
        expect(lambda do
          Cernel.purge_packages_from_a_list_of_kernels([])
        end).to raise_error SystemExit
      end

      it "prints 'no packages error' message" do
        Kernel.stub!(:exit)
        $stderr.should_receive(:puts).with("ERROR: No packages to remove.")
        Cernel.purge_packages_from_a_list_of_kernels([])
      end
    end

    context "when kernels_to_remove.length is > 0" do
      context "when packages found" do
        it "prints 'packages being uninstalled' message" do
          Cernel.stub!(:find_kernel_packages).and_return("package1 package2")
          #$stdout.should_receive(:puts).with("Packages are being uninstalled, please stand by...") ## couldn't get this work, why?
          output = capture_stdout { Cernel.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1)) }
          expect(output).to match "Packages are being uninstalled, please stand by..."
        end

        it "runs `apt-get purge -y` command" do
          IO.should_receive(:popen).with("sudo apt-get purge -y package1 package2")
          Cernel.stub!(:find_kernel_packages).and_return("package1 package2")
          Cernel.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1))
        end
      end
    end
  end

  context "#get_free_disk_space" do
    it "gets available disk space" do
      Kernel.should_receive(:`).with("df -BM /boot").
        and_return("Filesystem     1M-blocks  Used Available Use% Mounted on\n/dev/sdc3         46935M 9115M    35437M  21% /\n")

      Cernel.get_free_disk_space
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
          Cernel.send(:confirm_removals, @installed_kernels.first(0), @installed_kernels)
        end).to raise_error SystemExit
      end

      it "prints 'no kernels selected' message" do
        Kernel.stub!(:exit)
        $stderr.should_receive(:puts).with("No kernels selected!")
        Cernel.send(:confirm_removals, @installed_kernels.first(0), @installed_kernels)
      end
    end
  end
end
