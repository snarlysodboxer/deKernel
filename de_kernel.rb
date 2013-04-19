class DeKernel
  def self.run
    system "clear"
    puts "It's generally recommended to leave at least three of your latest kernels"
    all_kernels       = Kernels.find_all_kernels
    installed_kernels = Kernels.find_installed_kernels(all_kernels)
    kernels_to_remove = Kernels.ask_which_to_remove(installed_kernels)
    Kernels.purge_packages_from_kernels_list(kernels_to_remove)
    Kernels.print_other_kernels_message
  end
end