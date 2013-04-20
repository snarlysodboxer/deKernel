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
end

