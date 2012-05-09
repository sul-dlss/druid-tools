#require File.expand_path('../spec_helper',__FILE__)
#puts $LOAD_PATH.join("\n")
require 'druid-tools'

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
  end
  
  describe "content discovery" do
    it "should find content in content directories" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      File.open(File.join(druid.content_dir,'someContent'),'w') { |f| f.write 'This is the content' }
      druid.find_content('someContent').should == File.join(druid.content_dir,'someContent')
    end
    
    it "should find content in the root directory" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      File.open(File.join(druid.path(nil,true),'someContent'),'w') { |f| f.write 'This is the content' }
      druid.find_content('someContent').should == File.join(druid.path,'someContent')
    end
    
    it "should not find content in the wrong content directory" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      File.open(File.join(druid.metadata_dir,'someContent'),'w') { |f| f.write 'This is the content' }
      druid.find_content('someContent').should be_nil
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
    
    it "raises SameContentExistsError if the link to source already exists" do
      @dr.mkdir_with_final_link(@source_dir)
      lambda { @dr.mkdir_with_final_link(@source_dir) }.should raise_error(DruidTools::SameContentExistsError)
    end
    
    it "raises DifferentContentExistsError if a directory already exists in the workspace for this druid" do
      @dr.mkdir(@fixture_dir)
      lambda { @dr.mkdir_with_final_link(@source_di) }.should raise_error(DruidTools::DifferentContentExistsError)
    end
  end
  
end
