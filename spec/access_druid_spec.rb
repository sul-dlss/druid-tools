require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe DruidTools::PurlDruid do

    let(:purl_root) { Dir.mktmpdir }

    let(:druid) { DruidTools::PurlDruid.new 'druid:cd456ef7890', purl_root }

    after(:each) do
      FileUtils.remove_entry purl_root
    end

    it "overrides Druid#tree so that the leaf is not Druid#id" do
      expect(druid.tree).to eq(['cd','456','ef','7890'])
    end

    describe "#content_dir" do

      it "creates content directories at leaf of the druid tree" do
        expect(druid.content_dir).to match(/ef\/7890$/)
      end

      it "does not create a 'content' subdirectory" do
        expect(druid.content_dir).to_not match(/content$/)
      end
    end

end
