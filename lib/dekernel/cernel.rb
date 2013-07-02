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
      kernels_to_remove = select_kernels_for_removal(installed_kernels)
    end

    def purge_packages_from_a_list_of_kernels(kernels_to_remove)
      ($stderr.puts "\n" + "No kernels selected!" ; Kernel.exit) unless kernels_to_remove.length > 0
      confirm_removals(kernels_to_remove) unless $options[:no_confirm]
      packages_list = find_kernel_packages(kernels_to_remove)
      IO.popen("sudo apt-get purge #{apt_options} #{packages_list.join("\s")} 1>&2") { |p| p.each { |f| $stdout.puts f } }
      if $?.exitstatus.zero?
        $stdout.puts Message.purge_packages_success(kernels_to_remove)
        Kernel.system "sudo apt-get clean" unless $options[:dry_run]
      else
        $stdout.puts Message.purge_packages_failure($?)
      end
    end

    def get_free_disk_space
      Kernel.send(:`, "df -BM /boot").split[10].to_i
    end

    def find_all_except_latest(number)
      kernels = find_kernels
      installed_kernels = kernels[:installed]
      sort_properly(installed_kernels).take(installed_kernels.length - number)
    end

    def safe_ified_kernels_list
      options = $options[:kernels_list].split(" ").reject { |kernel| kernel =~ (/[a-z]/i) }
      options = options.reject { |kernel| kernel =~ (/[0-9]{3,}/i) }
      options.select { |kernel| kernel =~ kernel_regex }
    end


    private
    def find_all_kernels
      Kernel.send(:`, "ls /boot").each_line.grep(/vmlinuz/).collect { |l|
        l.match(kernel_regex).to_s
      }
    end

    def kernel_regex
      /[0-9]\.[0-9]{1,2}\.[0-9]{1,2}-[0-9]{1,2}/
    end

    def find_installed_kernels(all_kernels)
      all_kernels.select { |kernel|
        Kernel.send(:system, "dpkg-query -f '${Package}\n' -W *#{kernel}* >/dev/null 2>&1")
      }
    end

    def select_kernels_for_removal(installed_kernels)
      installed_kernels.select { |kernel|
        $stdout.print "Do you want to remove the #{kernel} kernel [y/N/yes/NO/?]"
        Signal.trap("SIGINT") { $stdout.puts "\nCaught exit signal, exiting!" ; Kernel.exit }
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

    def confirm_removals(kernels_to_remove)
      all_kernels = find_kernels
      installed_kernels = all_kernels[:installed]
      Kernel.system "clear"
      Signal.trap("SIGINT") { $stdout.puts "\nCaught exit signal, exiting!" ; Kernel.exit }
      $stdout.puts Message.ask_to_confirm_kernels_to_remove(kernels_to_remove, installed_kernels)
      ($stderr.puts "Canceled!" ; Kernel.exit) unless !!ARGF.first.strip.match(/^y$|^yes$/i)
      kernels_to_remove
    end

    def sort_properly(kernels)
      kernels.sort_by { |kernel_string|
        split = kernel_string.split(/-/)
        [split[0], "%02d" % split[1]].join('-')
      }
    end

    def apt_options
      options = Array.new
      if $options[:assume_yes] ; options << "-y" ; end
      if $options[:dry_run] ; options << "-s" ; end
      options.join(" ").strip
    end
  end
end

