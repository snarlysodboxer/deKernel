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

  context "#find_all_kernels" do
    before :each do
      Kernel.should_receive(:`).with("ls /boot").
        and_return("vmlinuz-2.28.10-38-generic\nvmlinuz-3.2.0-39-generic\nvmlinuz-3.2.0-40-generic\n")
    end

    it "returns an array" do
      expect(Cernel.send(:find_all_kernels)).to be_a_kind_of(Array)
    end

    it "returns greped kernel numbers" do
      expect(Cernel.send(:find_all_kernels)).to eq ["2.28.10-38", "3.2.0-39", "3.2.0-40"]
    end
  end

  context "#find_installed_kernels(all_kernels)" do
    it "returns an array" do
      expect(Cernel.send(:find_installed_kernels, @all_kernels)).to be_a_kind_of(Array)
    end

    it "calls dpkg command for each kernel" do
      @all_kernels.each do |kernel|
        Kernel.stub!(:`).with("dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1")
        Kernel.should_receive(:system).with("dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1").
          and_return("linux-headers-#{kernel}\nlinux-headers-#{kernel}-generic\nlinux-image-#{kernel}-generic\n")
      end
      Cernel.send(:find_installed_kernels, @all_kernels)
    end

    it "returns only kernels that have installed packages" do
      { "true" => @installed_kernels, "false" => @other_kernels }.each do |value, kernels|
        kernels.each do |kernel|
          Kernel.stub!(:system).
            with("dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1").
              and_return(!!value.match(/true/))
        end
      end
      expect(Cernel.send(:find_installed_kernels, @all_kernels)).to eq @installed_kernels
    end
  end

  #   create_kernels_to_remove_list(installed_kernels)

  context "#find_kernel_packages(kernels_to_remove)" do
    it "returns an array" do
      expect(Cernel.send(:find_kernel_packages, @installed_kernels.drop(2))).to be_a_kind_of(Array)
    end

    it "returns only packages from the kernels_to_remove" do
      remove_packages = Array.new
      @remove_kernels.each do |kernel|
        packages = ["linux-headers-#{kernel}", "linux-headers-#{kernel}-generic", "linux-image-#{kernel}-generic"]
        Kernel.should_receive(:`).with("dpkg-query -f '${Package}\n' -W *#{kernel}*").
          and_return(packages.join("\n"))
        packages.each do |package|
          remove_packages << package
        end
      end
      (@all_kernels - @remove_kernels).each do |kernel|
        Kernel.should_not_receive(:system).with("dpkg-query -f '${Package}\n' -W *#{kernel}*")
      end

      expect(Cernel.send(:find_kernel_packages, @remove_kernels)).to eq remove_packages
    end
  end

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
