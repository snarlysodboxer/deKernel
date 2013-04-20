require 'spec_helper'

describe 'Messages' do
  context "#print_installed_kernels(installed_kernels)" do
    context "prints kernel count" do
      it "when installed_kernels = 0" do
        expect(lambda do
          Messages.print_installed_kernels([])
        end).to raise_error "ERROR: No kernels found in the /boot directory!"
      end

      it "when installed_kernels = 1" do
        output = capture_stout do
          Messages.print_installed_kernels(@installed_kernels.last(1))
        end

        expect(output).to match "Only one kernel found!"
      end

      it "when installed_kernels > 1" do
        output = capture_stout do
          Messages.print_installed_kernels(@installed_kernels)
        end

        expect(output).to match "Found #{@installed_kernels.length} kernels installed:"
      end
    end

    it "prints kernels" do
      output = capture_stout do
        Messages.print_installed_kernels(@installed_kernels)
      end

      @installed_kernels.each do |kernel|
        expect(output).to match kernel
      end
    end
  end
  context "#print_other_kernels"
  context "#print_purge_packages_success(kernels_to_remove)"
  context "#print_purge_packages_failure(exit_code)"
  context "#confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)"

  # private methods, test them or not?
  #   print_kernel_count(installed_kernels)

end
