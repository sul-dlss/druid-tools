# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DruidTools::PurlDruid do
  let(:purl_root) { Dir.mktmpdir }

  let(:druid) { described_class.new 'druid:cd456ef7890', purl_root }

  after do
    FileUtils.remove_entry purl_root
  end

  it 'overrides Druid#tree so that the leaf is not Druid#id' do
    expect(druid.tree).to eq(%w[cd 456 ef 7890])
  end

  describe '#content_dir' do
    it 'creates content directories at leaf of the druid tree' do
      expect(druid.content_dir).to match(%r{ef/7890$})
    end

    it "does not create a 'content' subdirectory" do
      expect(druid.content_dir).not_to match(/content$/)
    end
  end
end
