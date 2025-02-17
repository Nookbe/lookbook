require "rails_helper"

RSpec.describe Lookbook::Params do
  context ".build_param" do
    it "returns a hash of param info" do
      tag = build(:param_tag)
      param_data = Lookbook::Params.build_param(tag)
      expect(param_data).to be_a Hash
    end

    context "JSON options" do
      let(:json) { JSON.parse(File.read(Rails.root.join("data/icons.json"))) }

      it "can be loaded from a JSON file with root-relative path" do
        tag = build(:param_tag, text: "select data/icons.json")
        param_data = Lookbook::Params.build_param(tag)
        expect(param_data[:options]).to eq json
      end

      it "can be loaded from a JSON file relative to the code object file" do
        tag = build(:param_tag,
          text: "select ../icons.json",
          file: Rails.root.join("data/foobar/example_preview.rb"))
        param_data = Lookbook::Params.build_param(tag)
        expect(param_data[:options]).to eq json
      end
    end
  end
end
