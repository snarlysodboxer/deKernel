class Message
  class << self
    def installed_kernels(installed_kernels)
      string = String.new
      string << "#{kernel_count(installed_kernels)}\n"
      installed_kernels.each { |k| string << "  #{k}  \n" }
      string
    end

    def other_kernels
      kernels = Cernel.find_kernels
      other_kernels = kernels[:all] - kernels[:installed]
      string = String.new
      if other_kernels.length > 0
        list_command = "###       `"
        other_kernels.each_with_index do |kernel, index|
          index + 1 == other_kernels.length ? (
            list_command << "sudo ls -ahl /boot/*-#{kernel}*" ) : (
            list_command << "sudo ls -ahl /boot/*-#{kernel}* && " )
        end
        list_command << "`"
        remove_command = "###       `"
        other_kernels.each_with_index do |kernel, index|
          index + 1 == other_kernels.length ? (
            remove_command << "sudo rm -f   /boot/*-#{kernel}*" ) : (
            remove_command << "sudo rm -f   /boot/*-#{kernel}* && " )
        end
        remove_command << "`"
        # ^^^ the above obviously needs refactored
        string = [
          "",
          "### NOTE: You have kernels in your /boot directory " +
          "that have no corresponding packages installed.",
          "###       If you know you don't want those kernels, " +
          "you may want to remove them.",
          "###       You can list and remove them with the following commands:",
          list_command,
          remove_command,
          "", ""].join("\n")
      end
      string
    end

    def purge_packages_success(kernels_to_remove)
      ["",
       "Successfully removed the kernel packages for: #{kernels_to_remove.join(', ')}",
       "",
       "### NOTE: Usually apt-get will update your bootloader automatically,",
       "###       but if you have any trouble you may need to update it manually.",
       "###       (i.e. `sudo update-grub2` if you are using grub2)"].join("\n")
    end

    def purge_packages_failure(exit_code)
      ["", "ERROR: apt-get purge failed with \"#{exit_code}\""].join("\n")
    end

    def confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
      string = String.new
      kernels_to_remove.length > 1 ? (
        string << "The #{kernels_to_remove.length} kernels marked with asterisks will be apt-get purged:\n") : (
        string << "The kernel marked with asterisks will be apt-get purged:\n")
      installed_kernels.each do |kernel|
        kernels_to_remove.include?(kernel) ? (string << "**#{kernel}**\n") : (string << "  #{kernel}  \n")
      end
      string << "Are you sure you want to continue [y/N/yes/NO/?]"
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
