require 'spec_helper'

describe 'Kernels' do
  context "#find_kernels"
  context "#ask_which_to_remove"
  context "#purge_packages_from_a_list_of_kernels" do
    context "when kernels_to_remove.length is 0" do
      it "should exit cleanly" do
        expect(lambda do
          Kernels.purge_packages_from_a_list_of_kernels([])
        end).to raise_error SystemExit
      end

      it "should print 'no kernels selected' message" do
        output = capture_stout do
          Kernels.purge_packages_from_a_list_of_kernels([])
        end
        message = "No kernels selected!"

        expect(output).to match message
      end
    end
  end

  # private methods, test them or not?
  #   find_all_kernels
  #   find_installed_kernels(all_kernels)
  #   create_kernels_to_remove_list(installed_kernels)
  #   find_kernel_packages(kernels_to_remove)
  #   confirm_removals(kernels_to_remove, installed_kernels)

end

