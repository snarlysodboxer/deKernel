class DeKernel
  def self.run
    system "clear"
    puts "It's generally recommended to leave at least three of your latest kernels installed."
    Kernels.purge_packages_from_a_list_of_kernels(Kernels.ask_which_to_remove)
    Messages.print_other_kernels
  end
end

