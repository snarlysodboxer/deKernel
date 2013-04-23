require 'spec_helper'

describe 'Message' do
  context "#installed_kernels(installed_kernels)" do
    context "when installed_kernels = 0" do
      it "returns 'no kernels found error' message" do
        expect(Message.installed_kernels([])).
          to match "ERROR: No kernels found in the /boot directory!"
      end
    end

    context "when installed_kernels = 1" do
      it "returns 'only one kernel found' message" do
        expect(Message.installed_kernels(@installed_kernels.last(1))).
          to match "Only one kernel found!"
      end
    end

    context "when installed_kernels > 1" do
      it "returns 'multiple kernels found' message" do
        expect(Message.installed_kernels(@installed_kernels)).
          to match "Found #{@installed_kernels.length} kernels installed:"
      end
    end

    it "returns kernels as a string" do
      expect(Message.installed_kernels(@installed_kernels)).
        to match ["Found #{@installed_kernels.length} kernels installed:"].
          concat(@installed_kernels.collect { |k| "  #{k}  " }).join("\n")
    end
  end

  context "#other_kernels" do
    context "when other_kernels.length is greater than 0" do
      it "returns 'you have other kernels' message" do
        Cernel.stub!(:find_kernels).and_return({ :all => @all_kernels, :installed => @installed_kernels })
        message = "### NOTE: You have kernels in your /boot directory " +
                  "that have no corresponding packages installed." + "\n"
                  "###       If you know you don't want those kernels, " +
                  "you may want to remove them."

        expect(Message.other_kernels).to match message
      end

      it "returns list and remove commands" do
        Cernel.stub!(:find_kernels).
          and_return({ :all => @all_kernels, :installed => @installed_kernels })

        [@other_kernels.first, "sudo ls -ahl ", "sudo rm -f "].each do |string|
          expect(Message.other_kernels).to match string
        end
      end
    end
    
    it "returns nothing if other_kernels.length == 0" do
      Cernel.stub!(:find_kernels).and_return({ :all => @all_kernels, :installed => @all_kernels })
      expect(Message.other_kernels).to be_empty
    end
  end

  context "#purge_packages_success(kernels_to_remove)" do
    it "returns successful purge message" do
      string = [
        "Successfully removed the kernel packages for: #{@all_kernels.drop(2).join(', ')}",
        "",
        "### NOTE: Usually apt-get will update your bootloader automatically,",
        "###       but if you have any trouble you may need to update it manually."].join("\n")
      expect(Message.purge_packages_success(@all_kernels.drop(2))).to match string
    end
  end

  context "#purge_packages_failure(exit_code)" do
    it "returns failed purge message" do
      string = 'ERROR: apt-get purge failed with \"12345\"'
      expect(Message.purge_packages_failure("12345")).to match string
    end
  end

  context "#confirm_kernels_to_be_removed(kernels_to_remove, installed_kernels)" do
    it "returns 'multiple kernels message' when multiple kernels" do
      output = Message.confirm_kernels_to_be_removed(@installed_kernels.drop(1),
                                                      @installed_kernels)

      expect(output).to match "The #{@installed_kernels.drop(1).length
                                     } kernels marked with asterisks will be apt-get purged:"
    end

    it "returns 'singular kernel message' when only one kernel" do
      output = Message.confirm_kernels_to_be_removed(@installed_kernels.first(1),
                                                      @installed_kernels)

      ["The kernel marked with asterisks will be apt-get purged:",
      "Are you sure you want to continue "].each do |string|
        expect(output).to match string
      end
    end
  end

  it "responds to purge_packages_success and purge_packages_failure methods" do
    ["success", "failure"].each do |boolean|
      expect(Message).to respond_to("purge_packages_#{boolean}")
    end
  end

  it "responds to list_command and remove_command methods" do
    ["list", "remove"].each do |name|
      expect(Message).to respond_to("#{name}_command")
    end
  end
end
