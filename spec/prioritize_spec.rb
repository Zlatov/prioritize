RSpec.describe Prioritize do

  let!(:ar_class) do
    class PostSection < ActiveRecord::Base
    end
  end
  subject(:extension_method_exist) { PostSection.methods.include? :prioritize_column }
  subject(:instance_method_use_exist) { PostSection.instance_methods.include? :priority_after }
  subject(:class_method_use_exist) {
    PostSection.methods.include?(:priority_after) &&
    PostSection.methods.include?(:priority_column) &&
    PostSection.methods.include?(:priority_column=)
  }

  it "Has a version number." do
    expect(Prioritize::VERSION).not_to be nil
  end

  it "Класс должен получить метод, который расширяет функционал." do
    expect(extension_method_exist).to eq(true)
  end

  context "До вызова расширяющего метода:" do
    it "* используемый метод у инстансев отсутствует." do
      expect(instance_method_use_exist).to eq(false)
    end

    it "* используемый метод у класса отсутствует." do
      expect(class_method_use_exist).to eq(false)
    end
  end

  context "После вызова расширяющего метода в классе:" do
    let!(:ar_class) do
      class PostSection
        prioritize_column
      end
    end

    it "* используемый метод у инстансев присутствует." do
      expect(instance_method_use_exist).to eq(true)
    end

    it "* используемый метод у класса присутствует." do
      expect(class_method_use_exist).to eq(true)
    end
  end
end
