class DeKernel
  def self.run
    original_free_space = Messages.get_free_disk_space
    Kernel.system "clear"
    puts "It's generally recommended to leave at least three of your latest kernels installed."
    Kernels.purge_packages_from_a_list_of_kernels(Kernels.ask_which_to_remove)
    Messages.print_other_kernels
  ensure
    begin
      $stdout.puts "#{Messages.get_free_disk_space - original_free_space} megabytes of disk space were freed."
    rescue
      $stderr.puts "ERROR: Unable to retrieve disk space"
    end
  end
end

