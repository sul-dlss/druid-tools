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

  it "validate druid strings using the valid? class method" do
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
      expect(DruidTools::Druid.valid?(dru)).to eq(exp)
    end
  end

  it "provides the full druid including the prefix" do
    expect(DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir).druid).to eq('druid:cd456ef7890')
    expect(DruidTools::Druid.new('cd456ef7890',@fixture_dir).druid).to eq('druid:cd456ef7890')
  end

  it "extracts the ID from the stem" do
    expect(DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir).id).to eq('cd456ef7890')
    expect(DruidTools::Druid.new('cd456ef7890',@fixture_dir).id).to eq('cd456ef7890')
  end

  it "raises an exception if the druid is invalid" do
    expect { DruidTools::Druid.new('nondruid:cd456ef7890',@fixture_dir) }.to raise_error(ArgumentError)
    expect { DruidTools::Druid.new('druid:cd4567ef890',@fixture_dir) }.to raise_error(ArgumentError)
  end

  it "builds a druid tree from a druid" do
    druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
    expect(druid.tree).to eq(['cd','456','ef','7890','cd456ef7890'])
    expect(druid.path).to eq(@tree_1)
  end

  it "creates and destroys druid directories" do
    expect(File.exists?(@tree_1)).to eq false
    expect(File.exists?(@tree_2)).to eq false

    druid_1 = DruidTools::Druid.new(@druid_1,@fixture_dir)
    druid_2 = DruidTools::Druid.new(@druid_2,@fixture_dir)

    druid_1.mkdir
    expect(File.exists?(@tree_1)).to eq true
    expect(File.exists?(@tree_2)).to eq false

    druid_2.mkdir
    expect(File.exists?(@tree_1)).to eq true
    expect(File.exists?(@tree_2)).to eq true

    druid_2.rmdir
    expect(File.exists?(@tree_1)).to eq true
    expect(File.exists?(@tree_2)).to eq false

    druid_1.rmdir
    expect(File.exists?(@tree_1)).to eq false
    expect(File.exists?(@tree_2)).to eq false
    expect(File.exists?(File.join(@fixture_dir,'cd'))).to eq false
  end

  describe "alternate prefixes" do
    before :all do
      DruidTools::Druid.prefix = 'sulair'
    end

    after :all do
      DruidTools::Druid.prefix = 'druid'
    end

    it "handles alternate prefixes" do
      expect { DruidTools::Druid.new('druid:cd456ef7890',@fixture_dir) }.to raise_error(ArgumentError)
      expect(DruidTools::Druid.new('sulair:cd456ef7890',@fixture_dir).id).to eq('cd456ef7890')
      expect(DruidTools::Druid.new('cd456ef7890',@fixture_dir).druid).to eq('sulair:cd456ef7890')
    end
  end

  describe "content directories" do
    it "knows where its content goes" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      expect(druid.content_dir(false)).to  eq(File.join(@tree_1,'content'))
      expect(druid.metadata_dir(false)).to eq(File.join(@tree_1,'metadata'))
      expect(druid.temp_dir(false)).to     eq(File.join(@tree_1,'temp'))

      expect(File.exists?(File.join(@tree_1,'content'))).to eq false
      expect(File.exists?(File.join(@tree_1,'metadata'))).to eq false
      expect(File.exists?(File.join(@tree_1,'temp'))).to eq false
    end

    it "creates its content directories on the fly" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      expect(druid.content_dir).to  eq(File.join(@tree_1,'content'))
      expect(druid.metadata_dir).to eq(File.join(@tree_1,'metadata'))
      expect(druid.temp_dir).to     eq(File.join(@tree_1,'temp'))

      expect(File.exists?(File.join(@tree_1,'content'))).to eq true
      expect(File.exists?(File.join(@tree_1,'metadata'))).to eq true
      expect(File.exists?(File.join(@tree_1,'temp'))).to eq true
    end

    it "matches glob" do
      druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      druid.mkdir
      expect(Dir.glob(File.join(File.dirname(druid.path), DruidTools::Druid::glob)).size).to eq(1)
    end
  end

  describe "content discovery" do
    before :all do
      @druid = DruidTools::Druid.new(@druid_1,@fixture_dir)
      @filelist = %w(1 2 3 4).collect { |num| "someFile#{num}" }
    end

    it "finds content in content directories" do
      location = @druid.content_dir
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      expect(@druid.find_content('someContent')).to eq(File.join(location,'someContent'))
    end

    it "finds content in the root directory" do
      location = @druid.path(nil,true)
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      expect(@druid.find_content('someContent')).to eq(File.join(location,'someContent'))
    end

    it "finds content in the leaf directory" do
      location = File.expand_path('..',@druid.path(nil,true))
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      expect(@druid.find_content('someContent')).to eq(File.join(location,'someContent'))
    end

    it "does not find content in the wrong content directory" do
      location = @druid.metadata_dir
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      expect(@druid.find_content('someContent')).to be_nil
    end

    it "does not find content in a higher-up directory" do
      location = File.expand_path('../..',@druid.path(nil,true))
      File.open(File.join(location,'someContent'),'w') { |f| f.write 'This is the content' }
      expect(@druid.find_content('someContent')).to be_nil
    end

    it "finds a filelist in the content directory" do
      location = Pathname(@druid.content_dir)
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(@druid.find_filelist_parent('content',@filelist)).to eq(location)
    end

    it "finds a filelist in the root directory" do
      location = Pathname(@druid.path(nil,true))
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(@druid.find_filelist_parent('content',@filelist)).to eq(location)
    end

    it "finds a filelist in the leaf directory" do
      location = Pathname(File.expand_path('..',@druid.path(nil,true)))
      @filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(@druid.find_filelist_parent('content',@filelist)).to eq(location)
    end

    it "raises an exception if the first file in the filelist is not found" do
      location = Pathname(@druid.content_dir)
      expect{@druid.find_filelist_parent('content',@filelist)}.to raise_exception(/content dir not found for 'someFile1' when searching/)
    end

    it "raises an exception if any other file in the filelist is not found" do
      location = Pathname(@druid.content_dir)
      location.join(@filelist.first).open('w') { |f| f.write "This is #{@filelist.first}" }
      expect{@druid.find_filelist_parent('content',@filelist)}.to raise_exception(/File 'someFile2' not found/)
    end

  end

  describe "#mkdir error handling" do
    it "raises SameContentExistsError if the directory already exists" do
      druid_2 = DruidTools::Druid.new(@druid_2,@fixture_dir)
      druid_2.mkdir
      expect { druid_2.mkdir }.to raise_error(DruidTools::SameContentExistsError)
    end

    it "raises DifferentContentExistsError if a link already exists in the workspace for this druid" do
      source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(source_dir)
      dr = DruidTools::Druid.new(@druid_2,@fixture_dir)
      dr.mkdir_with_final_link(source_dir)
      expect { dr.mkdir }.to raise_error(DruidTools::DifferentContentExistsError)
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

      expect(File).to be_symlink(@dr.path)
      expect(File.readlink(@tree_2)).to eq(@source_dir)
    end

    it "does not error out if the link to source already exists" do
      @dr.mkdir_with_final_link(@source_dir)
      expect(File).to be_symlink(@dr.path)
      expect(File.readlink(@tree_2)).to eq(@source_dir)
    end

    it "raises DifferentContentExistsError if a directory already exists in the workspace for this druid" do
      @dr.mkdir(@fixture_dir)
      expect { @dr.mkdir_with_final_link(@source_di) }.to raise_error(DruidTools::DifferentContentExistsError)
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
        #Nil the create records for this context because we're in a known read only one
        
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
      #Make sure a delete record is not present
      expect(dr1.deletes_record_exists?).to be_falsey
      
      #Nil the create records for this test 
      dr1.mkdir
      dr1.prune!
      expect(File).to_not exist(File.join(workspace, 'cd'))
      expect(File).to exist(workspace)
      
      #Make sure a delete record was created
      expect(dr1.deletes_dir_exists?).to be_truthy
      expect(dr1.deletes_record_exists?).to be_truthy
    end

    it "removes directories with symlinks" do
      #Make sure a delete record is not present
      expect(dr2.deletes_record_exists?).to be_falsey
      
      #Nil the create records for this test 
      source_dir = File.join workspace, 'src_dir'
      FileUtils.mkdir_p(source_dir)
      dr2.mkdir_with_final_link(source_dir)
      dr2.prune!
      expect(File).to_not exist(dr2.path)
      expect(File).to_not exist(File.join(workspace, 'cd'))
      
      #Make sure a delete record was created
      expect(dr2.deletes_dir_exists?).to be_truthy
      expect(dr2.deletes_record_exists?).to be_truthy
    end
    
    describe "logging deleted druids" do
      
            #Purge any paths or delete records created in the test
            after :each do
              #Remove the .deletes dir to clean up
              dr2.deletes_delete_record if dr2.deletes_record_exists?
              FileUtils.rm_rf dr2.deletes_dir_pathname
              
            end
      
            it "returns the path to the .deletes directory as a Pathname" do
              expect(dr2.deletes_dir_pathname.class).to eq(Pathname)
            end
            
            it "returns the path to the delete record for a druid as a Pathname" do
              expect(dr2.deletes_record_pathname.class).to eq(Pathname)
            end
            
            it "returns the path to the delete record for a druid as top_level/.deletes/druid" do
               expect(dr2.deletes_record_pathname.to_s).to eq("#{dr2.base}/.deletes/#{dr2.id}")
            end
      
            it "returns false when the .deletes dir is not present on the file system" do
              expect(dr2.deletes_dir_exists?).to be_falsey 
            end
      
            it "creates the .deletes dir and detect it exists" do
      
              #Clean the .deletes dir if present
              FileUtils.rm_rf dr2.deletes_dir_pathname
        
              #Test for exists? and create
              expect(dr2.deletes_dir_exists?).to be_falsey 
              dr2.create_deletes_dir
              expect(dr2.deletes_dir_exists?).to be_truthy
            end
      
            it "returns false when the .deletes dir does not have a deleted record for a druid" do
              expect(dr2.deletes_record_exists?).to be_falsey
            end
            
            it "creates a deleted record with a parent directory that has no .deletes directory and no deleted for the file and successfully create a delete record there" do
              #Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
              expect(dr2.deletes_dir_exists?).to be_falsey 
              expect(dr2.deletes_record_exists?).to be_falsey
              
              #Create the delete record
              dr2.creates_delete_record
              
              #Check to ensure items were created
              expect(dr2.deletes_dir_exists?).to be_truthy
              expect(dr2.deletes_record_exists?).to be_truthy
            end
            
            it "creates a delete record with a parent directory that has a .deletes directory that does not contain a delete record for this druid" do
              #Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
              expect(dr2.deletes_dir_exists?).to be_falsey 
              expect(dr2.deletes_record_exists?).to be_falsey
              
              #Creates the deletes dir and check
              dr2.create_deletes_dir
              expect(dr2.deletes_dir_exists?).to be_truthy
              expect(dr2.deletes_record_exists?).to be_falsey
              
              #Create the delete record
              dr2.creates_delete_record
              
              #Check to ensure items were created
              expect(dr2.deletes_dir_exists?).to be_truthy
              expect(dr2.deletes_record_exists?).to be_truthy
            end
            
            it "creates a delete record with a parent directory that does not have a .deletes directory and contains an older delete record" do
              #Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
              expect(dr2.deletes_dir_exists?).to be_falsey 
              expect(dr2.deletes_record_exists?).to be_falsey
              
              dr2.creates_delete_record
              time = Time.now
              expect(File.mtime(dr2.deletes_record_pathname)).to be <= time
              sleep(1) #force a one second pause in case the machine is fast (as in not some old Commodore64), since mtime only goes down to the second
              
              dr2.creates_delete_record
              #Should have a new newer deleted record
              expect(File.mtime(dr2.deletes_record_pathname)).to be > time
            end
    end
  end
end
