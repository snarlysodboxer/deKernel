class DeKernel
  def self.deKernel
    system "clear"
    puts "It's generally recommended to leave at least three of your latest kernels"
    all_kernels = Array.new
    `ls /boot | grep vmlinuz | cut -d'-' -f2,3`.each_line { |l| all_kernels << l.strip }
    installed_kernels = all_kernels.select do |k|
      `dpkg -l | grep ^ii | grep "#{k}"`
      $? == 0 ? true : false
    end
    count = installed_kernels.length
    case
    when count == 0
      puts "ERROR: No kernels found in /boot"
    when count == 1
      puts "Only one kernel found!"
    when count >= 2
      puts "Found #{count} kernels installed:"
    end
    installed_kernels.each { |k| puts k }
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
    puts "The kernels marked with asterisks will be apt-get purged:"
    installed_kernels.each do |kernel|
      if kernels_to_remove.include? kernel
        puts "**#{kernel}**"
      else
        puts "  #{kernel}  "
      end
    end
    puts "Are you sure you want to continue? (y/N, yes/No)"
    arg = ARGF.first.strip
    if arg == "y" || arg == "yes"
      packages = String.new
      kernels_to_remove.each do |kernel|
        $stdout.flush
        puts kernel
        packages += `dpkg -l | grep ^ii | grep "#{kernel}" | cut -d' ' -f3`
      end
      unless packages == ""
        puts "Packages are being uninstalled, please stand by..."
        `apt-get purge -y #{packages.split.join("\s")}`
        if $? == 0
          puts "Successfully removed the kernel packages for: #{kernels_to_remove}"
          puts "Now you will want to update your bootloader."
          puts "    (i.e. `sudo update-grub2` if you are using grub2)"
        else
          puts "ERROR: apt-get purge failed with exit code #{$?}"
        end
      else
        puts "ERROR: No packages to remove."
      end
    else
      puts "Canceled!"
    end
    other_kernels = all_kernels - installed_kernels
    if other_kernels.length > 0
      list_command = "sudo "
      other_kernels.each_with_index do |kernel, index|
        if index + 1 == other_kernels.length
          list_command += "ls -ahl /boot/*-#{kernel}*"
        else
          list_command += "ls -ahl /boot/*-#{kernel}* && "
        end
      end

      remove_command = "sudo "
      other_kernels.each_with_index do |kernel, index|
        if index + 1 == other_kernels.length
          remove_command += "rm /boot/*-#{kernel}* -f"
        else
          remove_command += "rm /boot/*-#{kernel}* -f && "
        end
      end
      puts ""
      puts "### NOTE: You have kernels in your /boot directory that have no corresponding packages installed."
      puts "###   You can list them with:"
      puts "###   `#{list_command}`"
      puts "###   If you know you don't want those kernels, you may want to remove them with something like:"
      puts "###   `#{remove_command}`"
      puts ""
    end
  end
end

DeKernel.deKernel