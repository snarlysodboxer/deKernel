class Cernel
  class << self
    def find_kernels
      all_kernels = find_all_kernels
      installed_kernels = find_installed_kernels(all_kernels)
      { all: all_kernels, installed: installed_kernels }
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
      if $options[:dry_run] == true
        IO.send(:popen, "sudo apt-get purge --dry-run #{packages_list.join("\s")} 1>&2") { |p| p.each { |f| $stdout.puts f } }
      else
        IO.send(:popen, "sudo apt-get purge #{packages_list.join("\s")} 1>&2") { |p| p.each { |f| $stdout.puts f } }
      end
      if $? != 0
        $stdout.puts Message.purge_packages_failure($?)
      else
        $stdout.puts Message.purge_packages_success(kernels_to_remove)
        Kernel.system "sudo apt-get clean"
      end
    end

    def get_free_disk_space
      Kernel.send(:`, "df -BM /boot").split[10].to_i
    end

    private
    def find_all_kernels
      Kernel.send(:`, "ls /boot").each_line.grep(/vmlinuz/).collect { |l|
        l.match(/[0-9]\.[0-9]{1,2}\.[0-9]{1,2}-[0-9]{1,2}/).to_s
      }
    end

    def find_installed_kernels(all_kernels)
      all_kernels.select { |kernel|
        Kernel.send(:system, "dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1")
      }
    end

    def create_kernels_to_remove_list(installed_kernels)
      installed_kernels.select { |kernel|
        $stdout.print "Do you want to remove the #{kernel} kernel [y/N/yes/NO/?]"
        next unless !!ARGF.first.strip.match(/^y$|^yes$/i)
        $stdout.puts "Marking #{kernel} for removal" ; true
      }
    end

    def find_kernel_packages(kernels_to_remove)
      packages = kernels_to_remove.map { |kernel|
        Kernel.send(:`, "dpkg-query -f '${Package}\n' -W *#{kernel}*").split("\n")
      }.flatten
      if packages.empty?
        $stderr.puts "ERROR: No packages to remove." ; Kernel.exit
      else
        $stdout.puts "Packages are being uninstalled, please stand by..."
      end ; packages
    end

    def confirm_removals(kernels_to_remove, installed_kernels)
      unless kernels_to_remove.length > 0
        $stderr.puts "\n" + "No kernels selected!" ; Kernel.exit
      else
        Kernel.system "clear"
        $stdout.puts Message.ask_to_confirm_kernels_to_remove(kernels_to_remove, installed_kernels)
        ($stderr.puts "Canceled!" ; Kernel.exit) unless !!ARGF.first.strip.match(/^y$|^yes$/i)
      end ; kernels_to_remove
    end
  end
end
