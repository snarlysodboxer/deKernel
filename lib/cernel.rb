class Cernel
  class << self
    def find_kernels
      all_kernels = find_all_kernels
      installed_kernels = find_installed_kernels(all_kernels)
      { :all => all_kernels, :installed => installed_kernels }
    end

    def ask_which_to_remove
      installed_kernels = find_kernels[:installed]
      $stdout.puts Message.installed_kernels(installed_kernels)
      Kernel.exit if installed_kernels.length == 0
      kernels_to_remove = create_kernels_to_remove_list(installed_kernels)
      confirm_removals(kernels_to_remove, installed_kernels)
    end

    def purge_packages_from_a_list_of_kernels(kernels_to_remove)
      packages_list = find_kernel_packages(kernels_to_remove)
      unless packages_list.nil?
        $stdout.puts "Packages are being uninstalled, please stand by..."
        IO.send(:popen, "sudo apt-get purge -y #{packages_list.split.join("\s")}") { |p| p.each { |f| $stdout.puts f } }
        $? == 0 ? result_and_message = ["success", kernels_to_remove] :
                  result_and_message = ["failure", $?]
        Kernel.system "sudo apt-get clean"
        $stdout.puts Message.send("purge_packages_#{result_and_message[0]}", result_and_message[1])
      end
    end

    def get_free_disk_space
      Kernel.send(:`, "df -BM /boot").split[10].to_i
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
        $stdout.print "Do you want to remove the #{kernel} kernel [y/N/yes/NO/?]"
        arg = ARGF.first.strip
        if arg == "y" or arg == "yes"
          $stdout.puts "Marking #{kernel} for removal"
          kernels_to_remove << kernel
        end
      end
      kernels_to_remove
    end

    def find_kernel_packages(kernels_to_remove)
      packages_list = String.new
      kernels_to_remove.each do |kernel|
        $stdout.flush
        $stdout.puts kernel
        packages_list += `dpkg -l | grep ^ii | grep "#{kernel}" | cut -d' ' -f3`
      end
      if packages_list == ""
        $stderr.puts "ERROR: No packages to remove."
        Kernel.exit
      else
        packages_list
      end
    end

    def confirm_removals(kernels_to_remove, installed_kernels)
      if kernels_to_remove.length > 0
        Kernel.system "clear"
        $stdout.puts Message.confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
        confirmation = ARGF.first.strip
        unless confirmation == "y" || confirmation == "yes"
          $stderr.puts "Canceled!"
          Kernel.exit
        end
      else
        $stderr.puts "No kernels selected!"
        Kernel.exit
      end
      kernels_to_remove
    end
  end
end