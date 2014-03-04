class DeKernel
  require 'dekernel/cernel'
  require 'dekernel/message'

  def run
    cernel_class = Cernel.new
    original_free_space = cernel_class.get_free_disk_space
    Kernel.system "clear"
    if $options[:dry_run]
      $stdout.puts "\n" + "      THIS IS A DRY-RUN!, apt-get will only pretend." + "\n" + "\n"
    end
    $stdout.puts  "It's generally recommended to leave at least " +
                  "three of your latest kernels installed." + "\n" + "\n"
    if $options[:all_except] != nil
      cernel_class.purge_packages_from_a_list_of_kernels(cernel_class.find_all_except_latest($options[:all_except]))
    elsif $options[:kernels_list] != nil
      cernel_class.purge_packages_from_a_list_of_kernels(cernel_class.safe_ified_kernels_list)
    else
      cernel_class.purge_packages_from_a_list_of_kernels(cernel_class.ask_which_to_remove)
    end
  ensure
    $stdout.puts Message.new.other_kernels
    $stdout.puts "#{cernel_class.get_free_disk_space - original_free_space} megabytes of disk space were freed."
  end
end
