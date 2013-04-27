class Message
  class << self
    ## Every method in this class returns a String object

    def installed_kernels(installed_kernels)
      [kernel_count(installed_kernels),
      (installed_kernels.collect { |k| "  #{k}  " })].flatten.push("", "").join("\n")
    end

    def other_kernels
      kernels = Cernel.find_kernels
      if (kernels[:all] - kernels[:installed]).length > 0
        ["",
         "### NOTE: You have kernels in your /boot directory " +
         "that have no corresponding packages installed.",
         "###       If you know you don't want those kernels, " +
         "you may want to remove them.",
         "###       You can list and remove them with the following commands:",
         list_and_remove_commands(kernels[:all] - kernels[:installed]),
         "", ""].join("\n")
      end or String.new
    end

    [:success, :failure].each { |exit_status|
      define_method "purge_packages_#{exit_status}" do |message|
        if exit_status == :success
          ["",
           "Successfully removed the kernel packages for: #{message.join(', ')}",
           "",
           "### NOTE: Usually apt-get will update your bootloader automatically,",
           "###       but if you have any trouble you may need to update it manually.",
           "###       (i.e. `sudo update-grub2` if you are using grub2)"]
        else
          ["", "ERROR: apt-get purge failed with \"#{message}\""]
        end.join("\n")
      end
    }

    def ask_to_confirm_kernels_to_remove(kernels_to_remove, installed_kernels)
      header_message = kernels_to_remove.length > 1 \
        ?  "The #{kernels_to_remove.length} kernels marked with asterisks will be apt-get purged:" \
        :  "The kernel marked with asterisks will be apt-get purged:"
      marked_up_kernels_list = installed_kernels.collect { |kernel|
        kernels_to_remove.include?(kernel) ? "**#{kernel}**" : "  #{kernel}  "
      }
      [header_message, marked_up_kernels_list, "",
       "Are you sure you want to continue [y/N/yes/NO/?]"].join("\n")
    end

    private
    { "list" => "ls -ahl", "remove" => "rm -f  " }.each { |name, command|
      define_method "#{name}_command" do |other_kernels|
        command = other_kernels.collect { |kernel| "sudo #{command} /boot/*-#{kernel}*" }.join(" && ")
        "###       `%s`" % command
      end
    }

    def list_and_remove_commands(other_kernels)
      [list_command(other_kernels), remove_command(other_kernels)].join("\n")
    end

    def kernel_count(installed_kernels)
      case installed_kernels.length
      when 0
        "ERROR: No kernels found in the /boot directory!"
      when 1
        "Only one kernel found!"
      when 2..(1.0/0.0)
        "Found #{installed_kernels.length} kernels installed:"
      end
    end
  end
end

