class DeKernel
  require 'dekernel/cernel'
  require 'dekernel/message'

  def self.run
    original_free_space = Cernel.get_free_disk_space
    Kernel.system "clear"
    if $options[:dry_run]
      $stdout.puts "\n" + "      THIS IS A DRY-RUN!, apt-get will only pretend." + "\n" + "\n"
    end
    $stdout.puts  "It's generally recommended to leave at least " +
                  "three of your latest kernels installed." + "\n" + "\n"
    Cernel.purge_packages_from_a_list_of_kernels(kernels_to_purge)
  ensure
    $stdout.puts Message.other_kernels
    $stdout.puts "#{Cernel.get_free_disk_space - original_free_space} megabytes of disk space were freed."
  end

  private
  def self.kernels_to_purge
    case
    when $options[:all_except]
      Cernel.find_all_except_latest($options[:all_except])
    when $options[:kernels_list]
      Cernel.safe_ified_kernels_list
    else
      Cernel.ask_which_to_remove
    end
  end
end
