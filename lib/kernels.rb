class Kernels
  class << self
    def find_kernels
      all_kernels = find_all_kernels
      installed_kernels = find_installed_kernels(all_kernels)
      { :all => all_kernels, :installed => installed_kernels }
    end

    def ask_which_to_remove
      installed_kernels = find_kernels[:installed]
      Messages.print_installed_kernels(installed_kernels)
      kernels_to_remove = create_kernels_to_remove_list(installed_kernels)
      confirm_removals(kernels_to_remove, installed_kernels)
    end

    def purge_packages_from_a_list_of_kernels(kernels_to_remove)
      packages_list = find_kernel_packages(kernels_to_remove)
      puts "Packages are being uninstalled, please stand by..."
      #`apt-get purge -y #{packages_list.split.join("\s")}`
      `apt-get purge -y #{packages_list.split.join("")}` ## TODO unbreak this
      $? == 0 ? result_and_message = ["success", kernels_to_remove] :
                result_and_message = ["failure", $?]
      Messages.send("print_purge_packages_#{result_and_message[0]}", result_and_message[1])
    end

    private
    def find_all_kernels
      all_kernels = Array.new
      `ls /boot | grep vmlinuz | cut -d'-' -f2,3`.each_line { |l| all_kernels << l.strip }
      all_kernels
    end

    def find_installed_kernels(all_kernels)
      installed_kernels = all_kernels.select do |kernel|
        `dpkg -l | grep ^ii | grep "#{kernel}"`
        $? == 0 ? true : false
      end
      installed_kernels
    end

    def create_kernels_to_remove_list(installed_kernels)
      kernels_to_remove = Array.new
      installed_kernels.each do |kernel|
        $stdout.flush
        print "Do you want to remove the #{kernel} kernel [y/N/yes/NO/?]"
        arg = ARGF.first.strip
        if arg == "y" or arg == "yes"
          puts "Marking #{kernel} for removal"
          kernels_to_remove << kernel
        end
      end
      kernels_to_remove
    end

    def find_kernel_packages(kernels_to_remove)
      packages_list = String.new
      kernels_to_remove.each do |kernel|
        $stdout.flush
        puts kernel
        packages_list += `dpkg -l | grep ^ii | grep "#{kernel}" | cut -d' ' -f3`
      end
      if packages_list == ""
        puts "ERROR: No packages to remove."
        Messages.print_other_kernels
        exit
      else
        packages_list
      end
    end

    def confirm_removals(kernels_to_remove, installed_kernels)
      puts ""
      if kernels_to_remove.length > 0
        system "clear"
        Messages.confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
        confirmation = ARGF.first.strip
        unless confirmation == "y" || confirmation == "yes"
          puts "Canceled!"
          Messages.print_other_kernels
          exit
        end
      else
        puts "No kernels selected!"
        Messages.print_other_kernels
        exit
      end
      kernels_to_remove
    end
  end
end
