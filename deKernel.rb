#!/usr/bin/env ruby

class DeKernel
  def self.deKernel
    system "clear"
    puts "It's generally recommended to leave at least three of your latest kernels"
    ask_which_kernels_to_remove
    confirm_kernel_removals
    purge_kernel_packages
    print_other_kernels_message
  end

  private
  class << self
    def find_all_kernels
      @all_kernels = Array.new
      `ls /boot | grep vmlinuz | cut -d'-' -f2,3`.each_line { |l| @all_kernels << l.strip }
    end
    def find_installed_kernels 
      find_all_kernels
      @installed_kernels = @all_kernels.select do |k|
        `dpkg -l | grep ^ii | grep "#{k}"`
        $? == 0 ? true : false
      end
    end
    def count_installed_kernels
      find_installed_kernels
      @count = @installed_kernels.length
    end
    def print_kernel_count_message
      count_installed_kernels
      case
      when @count == 0
        puts "ERROR: No kernels found in /boot"
      when @count == 1
        puts "Only one kernel found!"
      when @count >= 2
        puts "Found #{@count} kernels installed:"
      end
    end
    def print_installed_kernels
      print_kernel_count_message
      @installed_kernels.each { |k| puts "  #{k}  " }
    end
    def ask_which_kernels_to_remove 
      print_installed_kernels
      @kernels_to_remove = Array.new
      @installed_kernels.each do |kernel|
        $stdout.flush
        print "Do you want to remove the #{kernel} kernel? (y/N, yes/No)"
        arg = ARGF.first.strip
        if arg == "y" or arg == "yes"
          puts "Marking #{kernel} for removal"
          @kernels_to_remove << kernel
        end
      end
    end
    def confirm_kernel_removals
      system "clear"
      puts "The kernels marked with asterisks will be apt-get purged:"
      @installed_kernels.each do |kernel|
        if @kernels_to_remove.include? kernel
          puts "**#{kernel}**"
        else
          puts "  #{kernel}  "
        end
      end
      puts "Are you sure you want to continue? (y/N, yes/No)"
      confirmation = ARGF.first.strip
      unless confirmation == "y" || confirmation == "yes"
        puts "Canceled!"
        print_other_kernels_message
        exit
      end
    end
    def find_kernel_packages
      @packages_list = String.new
      @kernels_to_remove.each do |kernel|
        $stdout.flush
        puts kernel
        @packages_list += `dpkg -l | grep ^ii | grep "#{kernel}" | cut -d' ' -f3`
      end
      if @packages_list == ""
        puts "ERROR: No packages to remove."
        print_other_kernels_message
        exit
      end
    end
    def purge_kernel_packages
      find_kernel_packages
      puts "Packages are being uninstalled, please stand by..."
      `apt-get purge -y #{@packages_list.split.join("\s")}`
      if $? == 0
        puts "Successfully removed the kernel packages for: #{@kernels_to_remove}"
        puts "Now you will want to update your bootloader."
        puts "    (i.e. `sudo update-grub2` if you are using grub2)"
      else
        puts "ERROR: apt-get purge failed with exit code #{$?}"
      end
    end
    def other_kernels
      @other_kernels = @all_kernels - @installed_kernels
    end
    def print_other_kernels_message
      other_kernels
      if @other_kernels.length > 0
        list_command = "sudo "
        @other_kernels.each_with_index do |kernel, index|
          if index + 1 == @other_kernels.length
            list_command += "ls -ahl /boot/*-#{kernel}*"
          else
            list_command += "ls -ahl /boot/*-#{kernel}* && "
          end
        end

        remove_command = "sudo "
        @other_kernels.each_with_index do |kernel, index|
          if index + 1 == @other_kernels.length
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
end

DeKernel.deKernel