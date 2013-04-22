class DeKernel
  def self.run
    original_free_space = Cernel.get_free_disk_space
    Kernel.system "clear"
    $stdout.puts "It's generally recommended to leave at least three of your latest kernels installed."
    Cernel.purge_packages_from_a_list_of_kernels(Cernel.ask_which_to_remove)
  ensure
    $stdout.puts Message.other_kernels
    $stdout.puts "#{Cernel.get_free_disk_space - original_free_space} megabytes of disk space were freed."
  end
end

