class DeKernel
  def self.run
    original_free_space = Cernel.get_free_disk_space
    Kernel.system "clear"
    if $options[:dry_run]
      $stdout.puts "\n" + "      THIS IS A DRY-RUN!, apt-get will only pretend." + "\n" + "\n"
    end
    $stdout.puts "It's generally recommended to leave at least three of your latest kernels installed." + "\n" + "\n"
    if $options[:all_except] != nil
      Cernel.purge_packages_from_a_list_of_kernels(Cernel.find_all_except_latest($options[:all_except]))
    elsif $options[:kernels_list] != nil
      Cernel.purge_packages_from_a_list_of_kernels(Cernel.safe_ified_kernels_list)
    else
      Cernel.purge_packages_from_a_list_of_kernels(Cernel.ask_which_to_remove)
    end
  ensure
    $stdout.puts Message.other_kernels
    $stdout.puts "#{Cernel.get_free_disk_space - original_free_space} megabytes of disk space were freed."
  end
end


