class Message
  class << self
    ## Every method in this class returns a String

    def installed_kernels(installed_kernels)
      [kernel_count(installed_kernels),
      (installed_kernels.collect { |k| "  #{k}  " })].flatten.join("\n")
    end

    def other_kernels
      kernels = Cernel.find_kernels
      other_kernels = kernels[:all] - kernels[:installed]
      other_kernels.length > 0 ?
        ( ["",
           "### NOTE: You have kernels in your /boot directory " +
           "that have no corresponding packages installed.",
           "###       If you know you don't want those kernels, " +
           "you may want to remove them.",
           "###       You can list and remove them with the following commands:",
           list_and_remove_commands(other_kernels),
           "", ""].join("\n") ) :
        ( String.new )
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
      [(kernels_to_remove.length > 1 ?
         ( "The #{kernels_to_remove.length} kernels marked with asterisks will be apt-get purged:" ) :
         ( "The kernel marked with asterisks will be apt-get purged:" )),
       (installed_kernels.collect { |kernel|
          kernels_to_remove.include?(kernel) ? "**#{kernel}**" : "  #{kernel}  " }), "",
        "Are you sure you want to continue [y/N/yes/NO/?]"].join("\n")
    end

    private
    { "list" => "ls -ahl", "remove" => "rm -f  " }.each do |name, command|
      define_method "#{name}_command" do |other_kernels|
        #other_kernels.enum_for(:each_with_index).collect do |kernel, index| ## ruby-1.8.x compatible ?
        other_kernels.each_with_index.collect do |kernel, index|
          index + 1 == other_kernels.length ?
            ( "sudo #{command} /boot/*-#{kernel}*" ) :
            ( "sudo #{command} /boot/*-#{kernel}* && " )
        end.unshift("###       `").push("`").join
      end
    end

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
