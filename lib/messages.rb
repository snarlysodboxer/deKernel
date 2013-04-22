class Messages
  class << self
    def installed_kernels(installed_kernels)
      string = String.new
      string << "#{kernel_count(installed_kernels)}\n"
      installed_kernels.each { |k| string << "  #{k}  \n" }
      string
    end

    def other_kernels
      kernels = Kernels.find_kernels
      other_kernels = kernels[:all] - kernels[:installed]
      string = String.new
      if other_kernels.length > 0
        string << "\n"
        string << "### NOTE: You have kernels in your /boot directory that have no corresponding packages installed.\n"
        string << "###       If you know you don't want those kernels, you may want to remove them.\n"
        string << "###       You can list and remove them with the following commands:\n"
        {"list" => "ls -ahl", "remove" => "rm -f  "}.each do |name, command|
          string << "###       `"
          other_kernels.each_with_index do |kernel, index|
            index + 1 == other_kernels.length ? (
              string << "sudo #{command} /boot/*-#{kernel}*" ) : (
              string << "sudo #{command} /boot/*-#{kernel}* && " )
          end
          string << "`\n"
        end
        string << "\n"
      end
      string
    end

    def print_purge_packages_success(kernels_to_remove)
      $stdout.puts ""
      $stdout.puts "Successfully removed the kernel packages for: #{kernels_to_remove.join(', ')}"
      $stdout.puts ""
      $stdout.puts "### NOTE: Usually apt-get will update your bootloader automatically,"
      $stdout.puts "###       but if you have any trouble you may need to update it manually."
      $stdout.puts "###       (i.e. `sudo update-grub2` if you are using grub2)"
      $stdout.puts ""
    end

    def print_purge_packages_failure(exit_code)
      $stdout.puts ""
      $stderr.puts "ERROR: apt-get purge failed with \"#{exit_code}\""
    end

    def confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
      kernels_to_remove.length > 1 ?
        $stdout.puts("The #{kernels_to_remove.length} kernels marked with asterisks will be apt-get purged:") :
        $stdout.puts("The kernel marked with asterisks will be apt-get purged:")
      installed_kernels.each do |kernel|
        kernels_to_remove.include?(kernel) ? ($stdout.puts "**#{kernel}**") : ($stdout.puts "  #{kernel}  ")
      end
      $stdout.puts "Are you sure you want to continue [y/N/yes/NO/?]"
    end

    def get_free_disk_space
      Kernel.send(:`, "df -BM /boot").split[10].to_i
    end

    private
    def kernel_count(installed_kernels)
      count = installed_kernels.length
      case
      when count == 0
        "ERROR: No kernels found in the /boot directory!"
      when count == 1
        "Only one kernel found!"
      when count >= 2
        "Found #{count} kernels installed:"
      end
    end
  end
end
