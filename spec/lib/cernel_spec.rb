require 'spec_helper'

describe 'Cernel' do
  before :each do
    $stdout.stub!(:puts)
    $stdout.stub!(:print)
    $stderr.stub!(:puts)
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
      Cernel.stub!(:find_kernels).and_return({ installed: [] })
      expect(lambda { Cernel.ask_which_to_remove }).to raise_error SystemExit
    end

    it "prints each one and adds to list" do
      Cernel.stub!(:find_installed_kernels).and_return(@installed_kernels)
      ARGF.stub!(:first).and_return("y", "n", "y")

      expect(Cernel.ask_which_to_remove.to_s).to match(/#{@remove_kernels.to_s}/)
    end

    it "calls 'Message.installed_kernels(installed_kernels)'" do
      Kernel.stub!(:exit)
      Cernel.stub!(:find_kernels).and_return(@kernels_hash)
      Message.should_receive(:installed_kernels).with(@installed_kernels)
      ARGF.stub!(:first).and_return("y")

      Cernel.ask_which_to_remove
    end
  end

  context "#purge_packages_from_a_list_of_kernels(kernels_to_remove)" do
    before :each do
      IO.stub!(:popen)
      Message.stub!(:purge_packages_success)
      Message.stub!(:purge_packages_failure)
    end

    it "calls confirm_removals with $options[:no_confirm] = false (default)" do
      Cernel.stub!(:find_kernel_packages).and_return(@remove_packages)
      Cernel.should_receive(:confirm_removals).with(@remove_kernels)

      Cernel.purge_packages_from_a_list_of_kernels(@remove_kernels)
    end

    it "does not call confirm_removals with $options[:no_confirm] = true" do
      $options[:no_confirm] = true
      Cernel.stub!(:find_kernel_packages).and_return(@remove_packages)
      Cernel.should_not_receive(:confirm_removals).with(@remove_kernels)

      Cernel.purge_packages_from_a_list_of_kernels(@remove_kernels)
    end

    context "when kernels_to_remove.length is 0" do
      it "raises SystemExit" do
        expect(lambda do
          Cernel.purge_packages_from_a_list_of_kernels([])
        end).to raise_error SystemExit
      end

      it "prints 'no kernels selected' message" do
        Kernel.stub!(:exit)
        $stderr.should_receive(:puts).with("\nNo kernels selected!")

        Cernel.purge_packages_from_a_list_of_kernels([])
      end
    end


    it "prints 'no packages error' message" do
      Kernel.stub!(:exit)
      $stderr.should_receive(:puts).with("ERROR: No packages to remove.")
      Cernel.purge_packages_from_a_list_of_kernels([])
    end

    context "when kernels_to_remove.length is > 0" do
      context "when packages found" do
        before :each do
          Cernel.stub!(:confirm_removals).and_return(@remove_kernels)
        end

        it "prints 'packages being uninstalled' message" do
          Kernel.stub!(:`).with("dpkg-query -f '${Package}\n' -W *#{@installed_kernels.first}*").
            and_return("package1 package2")
          $stdout.should_receive(:puts).with("Packages are being uninstalled, please stand by...")

          Cernel.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1))
        end

        it "runs `apt-get purge` command with no options" do
          IO.should_receive(:popen).with("sudo apt-get purge  package1 package2 1>&2")
          Cernel.stub!(:find_kernel_packages).and_return(["package1", "package2"])

          Cernel.purge_packages_from_a_list_of_kernels(@installed_kernels.first(1))
        end

        it "does not run 'apt-get clean' command if $options[:dry_run] == true" do
          $options[:dry_run] = true
          $?.stub!(:exitstatus).and_return(0)
          IO.should_receive(:popen).with("sudo apt-get purge -s package1 package2 1>&2")
          Cernel.stub!(:find_kernel_packages).and_return(["package1", "package2"])
          Kernel.should_not_receive(:system).with("sudo apt-get clean")

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

  context "#find_all_except_latest(number)" do
    it "should find all except latest (number) kernels" do
      Cernel.stub!(:find_kernels).and_return(@kernels_hash)
      expect(Cernel.send(:find_all_except_latest, 1)).to eq @all_except_latest_one
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

  context "#create_kernels_to_remove_list(installed_kernels)" do
    it "returns an array" do
      ARGF.should_receive(:first).exactly(@installed_kernels.length).times.and_return('yes')
      expect(Cernel.send(:create_kernels_to_remove_list, @installed_kernels)).to be_a_kind_of(Array)
    end
    
    it "returns only the kernels selected" do
      ARGF.should_receive(:first).exactly(@installed_kernels.length).times.and_return('yes', 'no', 'no')
      expect(Cernel.send(:create_kernels_to_remove_list, @installed_kernels)).to eq @installed_kernels.first(1)
    end
  end

  context "#find_kernel_packages(kernels_to_remove)" do
    before :each do
      @remove_kernels.each do |kernel|
        Kernel.should_receive(:`).exactly(1).times.with("dpkg-query -f '${Package}\n' -W *#{kernel}*").
          and_return(@remove_packages.join("\n"))
      end
      (@all_kernels - @remove_kernels).each do |kernel|
        Kernel.should_not_receive(:system).with("dpkg-query -f '${Package}\n' -W *#{kernel}*")
      end
    end

    it "returns an array" do
      expect(Cernel.send(:find_kernel_packages, @remove_kernels)).to be_a_kind_of(Array)
    end

    it "returns only packages from the kernels_to_remove" do
      # why do i have to use 'uniq' right here? without 'uniq' it returns a doubled array.
      #expect(Cernel.send(:find_kernel_packages, @remove_kernels)).to eq @remove_packages
      expect(Cernel.send(:find_kernel_packages, @remove_kernels).uniq).to eq @remove_packages
    end
  end

  context "#confirm_removals(kernels_to_remove, installed_kernels)" do
    before :each do
      Cernel.stub!(:find_kernels).and_return(@kernels_hash)
      ARGF.should_receive(:first).exactly(1).times.and_return('no')
    end

    context "when confirmation not met" do
      it "raises system exit" do
        expect(lambda do
          Cernel.send(:confirm_removals, @remove_kernels)
        end).to raise_error SystemExit
      end

      it "prints 'canceled' message" do
        Kernel.stub!(:exit)

        $stderr.should_receive(:puts).with("Canceled!")
        Cernel.send(:confirm_removals, @remove_kernels)
      end
      
      it "returns kernels_to_remove" do
        Kernel.stub!(:exit)

        expect(Cernel.send(:confirm_removals, @remove_kernels)).to eq @remove_kernels
      end
    end
  end

  context "#sort_properly(kernels)" do
    it "pads dash-number" do
      unsorted  = ["2.23.10-1", "3.2.0-8", "2.23.1-4", "3.2.0-11", "2.3.1-10", "2.23.1-34"]
      sorted    = ["2.23.1-4", "2.23.1-34", "2.23.10-1", "2.3.1-10", "3.2.0-8", "3.2.0-11"]

      expect(Cernel.send(:sort_properly, unsorted)).to eq sorted
    end
  end

  context "#apt_options" do
    it "returns a string of the options" do
      $options[:assume_yes] = false
      $options[:dry_run] =    false
      expect(Cernel.send(:apt_options)).to eq ""

      $options[:assume_yes] = true
      $options[:dry_run] =    false
      expect(Cernel.send(:apt_options)).to eq "-y"

      $options[:assume_yes] = false
      $options[:dry_run] =    true
      expect(Cernel.send(:apt_options)).to eq "-s"

      $options[:assume_yes] = true
      $options[:dry_run] =    true
      expect(Cernel.send(:apt_options)).to eq "-y -s"
    end
  end
end
