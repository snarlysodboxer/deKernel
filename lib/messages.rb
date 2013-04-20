class Messages
  class << self
    def print_installed_kernels(installed_kernels)
      print_kernel_count(installed_kernels)
      installed_kernels.each { |k| puts "  #{k}  " }
    end

    def print_other_kernels
      kernels = Kernels.find_kernels
      other_kernels = kernels[:all] - kernels[:installed]
      if other_kernels.length > 0
        puts   ""
        puts   "### NOTE: You have kernels in your /boot directory that have no corresponding packages installed."
        puts   "###       If you know you don't want those kernels, you may want to remove them."
        puts   "###       You can list and remove them with the following commands:"
        {"list" => "ls -ahl", "remove" => "rm -f  "}.each do |name, command|
          print "###       `"
          other_kernels.each_with_index do |kernel, index|
            index + 1 == other_kernels.length ?
              print("sudo #{command} /boot/*-#{kernel}*") :
              print("sudo #{command} /boot/*-#{kernel}* && ")
          end
          print '`'
          puts  ""
        end
        puts    ""
      end
    end

    def print_purge_packages_success(kernels_to_remove)
      puts "Successfully removed the kernel packages for: #{kernels_to_remove.join(', ')}"
      puts ""
      puts "### NOTE: Now you will want to update your bootloader."
      puts "###       (i.e. `sudo update-grub2` if you are using grub2)"
      puts ""
    end

    def print_purge_packages_failure(exit_code)
      puts ""
      puts "ERROR: apt-get purge failed with exit code #{exit_code}"
    end

    def confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
      kernels_to_remove.length > 1 ?
        puts("The #{kernels_to_remove.length} kernels marked with asterisks will be apt-get purged:") :
        puts("The kernel marked with asterisks will be apt-get purged:")
      installed_kernels.each do |kernel|
        kernels_to_remove.include?(kernel) ? (puts "**#{kernel}**") : (puts "  #{kernel}  ")
      end
      puts "Are you sure you want to continue [y/N/yes/NO/?]"
    end

    private
    def print_kernel_count(installed_kernels)
      count = installed_kernels.length
      case
      when count == 0
        raise "ERROR: No kernels found in the /boot directory!"
      when count == 1
        puts "Only one kernel found!"
      when count >= 2
        puts "Found #{count} kernels installed:"
      end
    end
  end
end
