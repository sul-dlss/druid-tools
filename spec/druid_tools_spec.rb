require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
#puts $LOAD_PATH.join("\n")
require 'tmpdir'

describe DruidTools::Druid do
  before (:all) do
    @fixture_dir = File.expand_path("../fixtures",__FILE__)
    FileUtils.rm_rf(File.join(@fixture_dir,'cd'))
    @druid_1 = 'druid:cd456ef7890'
    @tree_1 = File.join(@fixture_dir,'cd/456/ef/7890/cd456ef7890')
    @druid_2 = 'druid:cd456gh1234'
    @tree_2 = File.join(@fixture_dir,'cd/456/gh/1234/cd456gh1234')
  end

  after(:each) do
    FileUtils.rm_rf(File.join(@fixture_dir,'cd'))
  end

  it "should be able to validate druid strings using the valid? class method" do
    tests = [
      # Expected     Input druid
      [true,         'druid:aa000bb0001'],
      [true,         'aa000bb0001'],
      [false,        'Aa000bb0001'],
      [false,        "xxx\naa000bb0001"],
      [false,        'aaa000bb0001'],
      [false,        'druidX:aa000bb0001'],
      [false,        ':aa000bb0001'],
      [true,         'aa123bb1234'],
      [false,        'aa12bb1234'],
      [false,        'aa1234bb1234'],
      [false,        'aa123bb123'],
      [false,        'aa123bb12345'],
      [false,        'a123bb1234'],
      [false,        'aaa123bb1234'],
      [false,        'aa123b1234'],
      [false,        'aa123bbb1234'],
      [false,        'druid:az918AZ9381'.upcase],
      [true,         'druid:az918AZ9381'.downcase],
      [true,         'druid:zz943vx1492']
    ]
    tests.each do |exp, dru|
      DruidTools::Druid.valid?(dru).should == exp
    end
  end

  it "should provide the full druid including the prefix" do
    DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir).druid.should == 'druid:cd456ef7890'
    DruidTools::Druid.new('cd456ef7890',@fixture_dir).druid.should == 'druid:cd456ef7890'
  end

  it "should extract the ID from the stem" do
    DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir).id.should == 'cd456ef7890'
    DruidTools::Druid.new('cd456ef7890',@fixture_dir).id.should == 'cd456ef7890'
  end

  it "should raise an exception if the druid is invalid" do
    lambda { DruidTools::Druid.new('nondruid:cd456ef7890',@fixture_dir) }.should raise_error(ArgumentError)
    lambda { DruidTools::Druid.new('druid:cd4567ef890',@fixture_dir) }.should raise_error(ArgumentError)
  end

  it "should build a druid tree from a druid" do
    druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
    druid.tree.should == ['cd','456','ef','7890','cd456ef7890']
    druid.path.should == @tree_1
  end

  it "should create and destroy druid directories" do
    File.exists?(@tree_1).should be_false
    File.exists?(@tree_2).should be_false

    druid_1 = DruidTools::Druid.new(@druid_1,@fixture_dir)
    druid_2 = DruidTools::Druid.new(@druid_2,@fixture_dir)

    druid_1.mkdir
    File.exists?(@tree_1).should be_true
    File.exists?(@tree_2).should be_false

    druid_2.mkdir
    File.exists?(@tree_1).should be_true
    File.exists?(@tree_2).should be_true

    druid_2.rmdir
    File.exists?(@tree_1).should be_true
    File.exists?(@tree_2).should be_false

    druid_1.rmdir
    File.exists?(@tree_1).should be_false
    File.exists?(@tree_2).should be_false
    File.exists?(File.join(@fixture_dir,'cd')).should be_false
  end

  describe "alternate prefixes" do
    before :all do
      DruidTools::Druid.prefix = 'sulair'
    end

    after :all do
      DruidTools::Druid.prefix = 'druid'
    end

    it "should handle alternate prefixes" do
      lambda { DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir) }.should raise_error(ArgumentError)
      DruidTools::Druid.new('sulair:cd456ef7890',@fixture_dir).id.should == 'cd456ef7890'
      DruidTools::Druid.new('cd456ef7890',@fixture_dir).druid.should == 'sulair:cd456ef7890'
    end
  end

  describe "content directories" do
    it "should know where its content goes" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      druid.content_dir(false).should  == File.join(@tree_1,'content')
      druid.metadata_dir(false).should == File.join(@tree_1,'metadata')
      druid.temp_dir(false).should     == File.join(@tree_1,'temp')

      File.exists?(File.join(@tree_1,'content')).should be_false
      File.exists?(File.join(@tree_1,'metadata')).should be_false
      File.exists?(File.join(@tree_1,'temp')).should be_false
    end

    it "should create its content directories on the fly" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      druid.content_dir.should  == File.join(@tree_1,'content')
      druid.metadata_dir.should == File.join(@tree_1,'metadata')
      druid.temp_dir.should     == File.join(@tree_1,'temp')

      File.exists?(File.join(@tree_1,'content')).should be_true
      File.exists?(File.join(@tree_1,'metadata')).should be_true
      File.exists?(File.join(@tree_1,'temp')).should be_true
    end

    it "should match glob" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      druid.mkdir
      Dir.glob(File.join(File.dirname(druid.path), DruidTools::Druid::glob)).size.should == 1
    end
  end

  describe "content discovery" do
    before :all do
      @druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      @filelist = %w(1 2 3 4).collect { |num| "someFile#{num}" }
    end

    it "should find content in content directories" do
      location = @druid.content_dir
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      @druid.find_content('someContent').should == File.join(location,'someContent')
    end

    it "should find content in the root directory" do
      location = @druid.path(nil,true)
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      @druid.find_content('someContent').should == File.join(location,'someContent')
    end

    it "should find content in the leaf directory" do
      location = File.expand_path('..',@druid.path(nil,true))
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      @druid.find_content('someContent').should == File.join(location,'someContent')
    end

    it "should not find content in the wrong content directory" do
      location = @druid.metadata_dir
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      @druid.find_content('someContent').should be_nil
    end

    it "should not find content in a higher-up directory" do
      location = File.expand_path('../..',@druid.path(nil,true))
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      @druid.find_content('someContent').should be_nil
    end

    it "should find a filelist in the content directory" do
      location = Pathname(@druid.content_dir)
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      @druid.find_filelist_parent('content',@filelist).should == location
    end

    it "should find a filelist in the root directory" do
      location = Pathname(@druid.path(nil,true))
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      @druid.find_filelist_parent('content',@filelist).should == location
    end

    it "should find a filelist in the leaf directory" do
      location = Pathname(File.expand_path('..',@druid.path(nil,true)))
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      @druid.find_filelist_parent('content',@filelist).should == location
    end

    it "should raise an exception if the first file in the filelist is not found" do
      location = Pathname(@druid.content_dir)
      lambda{@druid.find_filelist_parent('content',@filelist)}.should raise_exception(/content dir not found for 'someFile1' when searching/)
    end

    it "should raise an exception if any other file in the filelist is not found" do
      location = Pathname(@druid.content_dir)
      location.join(@filelist.first).open('w') { |f| f.write "This is #{@filelist.first}" }
      lambda{@druid.find_filelist_parent('content',@filelist)}.should raise_exception(/File 'someFile2' not found/)
    end

  end

  describe "#mkdir error handling" do
    it "raises SameContentExistsError if the directory already exists" do
      druid_2 = DruidTools::Druid.new(@druid_2,@fixture_dir)
      druid_2.mkdir
      lambda { druid_2.mkdir }.should raise_error(DruidTools::SameContentExistsError)
    end

    it "raises DifferentContentExistsError if a link already exists in the workspace for this druid" do
      source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(source_dir)
      dr = DruidTools::Druid.new(@druid_2,@fixture_dir)
      dr.mkdir_with_final_link(source_dir)
      lambda { dr.mkdir }.should raise_error(DruidTools::DifferentContentExistsError)
    end
  end

  describe "#mkdir_with_final_link" do

    before(:each) do
      @source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(@source_dir)
      @dr = DruidTools::Druid.new(@druid_2,@fixture_dir)
    end

    it "creates a druid tree in the workspace with the final directory being a link to the passed in source" do
      @dr.mkdir_with_final_link(@source_dir)

      File.should be_symlink(@dr.path)
      File.readlink(@tree_2).should == @source_dir
    end

    it "should not error out if the link to source already exists" do
      @dr.mkdir_with_final_link(@source_dir)
      File.should be_symlink(@dr.path)
      File.readlink(@tree_2).should == @source_dir
    end

    it "raises DifferentContentExistsError if a directory already exists in the workspace for this druid" do
      @dr.mkdir(@fixture_dir)
      lambda { @dr.mkdir_with_final_link(@source_di) }.should raise_error(DruidTools::DifferentContentExistsError)
    end
  end

  describe "#prune!" do

    let(:workspace) { Dir.mktmpdir }

    let(:dr1) { DruidTools::Druid.new @druid_1, workspace }
    let(:dr2) { DruidTools::Druid.new @druid_2, workspace }
    let(:pathname1) { dr1.pathname }

    after(:each) do
      FileUtils.remove_entry workspace
    end

    context "shared ancestor" do

      before(:each) do
        dr1.mkdir
        dr2.mkdir
        dr1.prune!
      end

      it "deletes the outermost directory" do
        expect(File).to_not exist(dr1.path)
      end

      it "deletes empty ancestor directories" do
        expect(File).to_not exist(pathname1.parent)
        expect(File).to_not exist(pathname1.parent.parent)
      end

      it "stops at ancestor directories that have children" do
        # 'cd/456' should still exist because of druid2
        shared_ancestor = pathname1.parent.parent.parent
        expect(shared_ancestor.to_s).to match(/cd\/456$/)
        expect(File).to exist(shared_ancestor)
      end
    end

    it "removes all directories up to the base path when there are no common ancestors" do
      dr1.mkdir
      dr1.prune!
      expect(File).to_not exist(File.join(workspace, 'cd'))
      expect(File).to exist(workspace)
    end

    it "removes directories with symlinks" do
      source_dir = File.join workspace, 'src_dir'
      FileUtils.mkdir_p(source_dir)
      dr2.mkdir_with_final_link(source_dir)
      dr2.prune!
      expect(File).to_not exist(dr2.path)
      expect(File).to_not exist(File.join(workspace, 'cd'))
    end
  end

end
