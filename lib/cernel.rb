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
      packages_list.empty? ?
        ( $stderr.puts "ERROR: No packages to remove." ; Kernel.exit ) :
        ( $stdout.puts "Packages are being uninstalled, please stand by..."
          IO.send(:popen, "sudo apt-get purge #{packages_list.join("\s")}") { |p| p.each { |f| $stdout.puts f } } )
        $? == 0 ?
          ( result_and_message = ["success", kernels_to_remove] ; Kernel.system "sudo apt-get clean" ) :
          ( result_and_message = ["failure", $?] )
        $stdout.puts Message.send("purge_packages_#{result_and_message[0]}", result_and_message[1])
    end

    def get_free_disk_space
      Kernel.send(:`, "df -BM /boot").split[10].to_i
    end

    private
    def find_all_kernels
      Kernel.send(:`, "ls /boot").each_line.grep(/vmlinuz/).collect { |l|
        l.match(/[0-9]\.[0-9]{1,2}\.[0-9]{1,2}-[0-9]{1,2}/).to_s }
    end

    def find_installed_kernels(all_kernels)
      all_kernels.select do |kernel|
        Kernel.send(:system, "dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1")
      end
    end

    def create_kernels_to_remove_list(installed_kernels)
      installed_kernels.select do |kernel|
        $stdout.print "Do you want to remove the #{kernel} kernel [y/N/yes/NO/?]"
        !!ARGF.first.strip.match(/^y$|^yes$/i) ?
          ( $stdout.puts "Marking #{kernel} for removal" ; true ) : ( false )
      end
    end

    def find_kernel_packages(kernels_to_remove)
      kernels_to_remove.map { |kernel|
        Kernel.send(:`, "dpkg-query -f '${Package}\n' -W *#{kernel}*").split("\n") }.flatten
    end

    def confirm_removals(kernels_to_remove, installed_kernels)
      kernels_to_remove.length > 0 ?
        ( Kernel.system "clear"
          $stdout.puts Message.confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)
          ($stderr.puts "Canceled!" ; Kernel.exit) unless ARGF.first.strip.match(/^y$|^yes$/i) ) :
        ( $stderr.puts ; $stderr.puts "No kernels selected!" ; Kernel.exit )
      kernels_to_remove
    end
  end
end
