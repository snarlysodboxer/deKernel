class Kernels
  class << self
    private
    def print_kernel_count_message(installed_kernels)
      count = installed_kernels.length
      case
      when count == 0
        puts "ERROR: No kernels found in /boot"
        exit
      when count == 1
        puts "Only one kernel found!"
      when count >= 2
        puts "Found #{count} kernels installed:"
      end
    end
    def print_installed_kernels(installed_kernels)
      installed_kernels.each { |k| puts "  #{k}  " }
    end
    def create_removal_list(installed_kernels)
      kernels_to_remove = Array.new
      installed_kernels.each do |kernel|
        $stdout.flush
        print "Do you want to remove the #{kernel} kernel? (y/N, yes/No)"
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
        print_other_kernels_message
        exit
      else
        packages_list
      end
    end
    def confirm_removals(kernels_to_remove, installed_kernels)
      system "clear"
      puts "The kernels marked with asterisks will be apt-get purged:"
      installed_kernels.each do |kernel|
        kernels_to_remove.include?(kernel) ? (puts "**#{kernel}**") : (puts "  #{kernel}  ")
      end
      puts "Are you sure you want to continue? (y/N, yes/No)"
      confirmation = ARGF.first.strip
      unless confirmation == "y" || confirmation == "yes"
        puts "Canceled!"
        Kernels.print_other_kernels_message
        exit
      end
    end

    public
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
    def ask_which_to_remove(installed_kernels)
      print_kernel_count_message(installed_kernels)
      print_installed_kernels(installed_kernels)
      kernels_to_remove = create_removal_list(installed_kernels)
      confirm_removals(kernels_to_remove, installed_kernels)
      kernels_to_remove
    end
    def purge_packages_from_kernels_list(kernels_to_remove)
      packages_list = find_kernel_packages(kernels_to_remove)
      puts "Packages are being uninstalled, please stand by..."
      `apt-get purge -y #{packages_list.split.join("\s")}`
      if $? == 0
        puts "Successfully removed the kernel packages for: #{kernels_to_remove}"
        puts "Now you will want to update your bootloader."
        puts "    (i.e. `sudo update-grub2` if you are using grub2)"
      else
        puts "ERROR: apt-get purge failed with exit code #{$?}"
      end
    end
    def print_other_kernels_message
      all_kernels = Kernels.find_all_kernels
      other_kernels = all_kernels - Kernels.find_installed_kernels(all_kernels)
      if other_kernels.length > 0
        puts      ""
        puts      "### NOTE: You have kernels in your /boot directory that have no corresponding packages installed."
        puts      "###       If you know you don't want those kernels, you may want to remove them."
        puts      "###       You can list and remove them with the following commands:"
        {"list" => "ls -ahl", "remove" => "rm -f  "}.each do |name, command|
          whole_command = String.new
          other_kernels.each_with_index do |kernel, index|
            index + 1 == other_kernels.length ?
              whole_command += "sudo #{command} /boot/*-#{kernel}*" :
              whole_command += "sudo #{command} /boot/*-#{kernel}* && "
          end
          puts    "###       `#{whole_command}`"
        end
        puts      ""
      end
    end
  end
end