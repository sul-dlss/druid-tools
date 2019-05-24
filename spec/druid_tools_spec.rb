# frozen_string_literal: true

RSpec.describe DruidTools::Druid do
  let(:fixture_dir) { File.expand_path('fixtures', __dir__) }
  let(:druid_str) { 'druid:cd456ef7890' }
  let(:tree1) { File.join(fixture_dir, 'cd/456/ef/7890/cd456ef7890') }
  let(:strictly_valid_druid_str) { 'druid:cd456gh1234' }
  let(:tree2) { File.join(fixture_dir, 'cd/456/gh/1234/cd456gh1234') }

  after do
    FileUtils.rm_rf(File.join(fixture_dir, 'cd'))
  end

  describe '.valid?' do
    # also tests .pattern
    it 'correctly validates druid strings' do
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
        expect(described_class.valid?(dru)).to eq(exp)
        expect(described_class.valid?(dru, false)).to eq(exp)
      end
    end
    context 'with strict validation' do
      it 'correctly validates druid strings' do
        tests = [
          # Expected     Input druid
          [false,        'aa000aa0000'],
          [false,        'ee000ee0000'],
          [false,        'ii000ii0000'],
          [false,        'oo000oo0000'],
          [false,        'uu000uu0000'],
          [false,        'll000ll0000'],
          [false,        'aa000bb0001'],
          [true,         'druid:dd000bb0001'],
          [false,        'druid:aa000bb0001'],
          [true,         'dd000bb0001'],
          [false,        'Dd000bb0001'],
          [false,        "xxx\ndd000bb0001"],
          [false,        'ddd000bb0001'],
          [false,        'druidX:dd000bb0001'],
          [false,        ':dd000bb0001'],
          [true,         'cc123bb1234'],
          [false,        'aa123bb1234'],
          [false,        'dd12bb1234'],
          [false,        'dd1234bb1234'],
          [false,        'dd123bb123'],
          [false,        'dd123bb12345'],
          [false,        'd123bb1234'],
          [false,        'ddd123bb1234'],
          [false,        'dd123b1234'],
          [false,        'dd123bbb1234'],
          [false,        'druid:bz918BZ9381'.upcase],
          [true,         'druid:bz918BZ9381'.downcase],
          [false,        'druid:az918AZ9381'.downcase],
          [true,         'druid:zz943vx1492']
        ]
        tests.each do |exp, dru|
          expect(described_class.valid?(dru, true)).to eq(exp)
        end
      end
    end
  end

  it '#druid provides the full druid including the prefix' do
    expect(described_class.new('druid:cd456ef7890', fixture_dir).druid).to eq('druid:cd456ef7890')
    expect(described_class.new('cd456ef7890', fixture_dir).druid).to eq('druid:cd456ef7890')
  end

  it '#id extracts the ID from the stem' do
    expect(described_class.new('druid:cd456ef7890', fixture_dir).id).to eq('cd456ef7890')
    expect(described_class.new('cd456ef7890', fixture_dir).id).to eq('cd456ef7890')
  end

  describe '#new' do
    it 'raises exception if the druid is invalid' do
      expect { described_class.new('nondruid:cd456ef7890', fixture_dir) }.to raise_error(ArgumentError)
      expect { described_class.new('druid:cd4567ef890', fixture_dir) }.to raise_error(ArgumentError)
    end
    it 'takes strict argument' do
      described_class.new(strictly_valid_druid_str, fixture_dir, true)
      expect { described_class.new(druid_str, fixture_dir, true) }.to raise_error(ArgumentError)
    end
  end

  it '#tree builds a druid tree from a druid' do
    druid = described_class.new(druid_str, fixture_dir)
    expect(druid.tree).to eq(%w[cd 456 ef 7890 cd456ef7890])
    expect(druid.path).to eq(tree1)
  end

  it '#mkdir, #rmdir create and destroy druid directories' do
    expect(File.exist?(tree1)).to eq false
    expect(File.exist?(tree2)).to eq false

    druid1 = described_class.new(druid_str, fixture_dir)
    druid2 = described_class.new(strictly_valid_druid_str, fixture_dir)

    druid1.mkdir
    expect(File.exist?(tree1)).to eq true
    expect(File.exist?(tree2)).to eq false

    druid2.mkdir
    expect(File.exist?(tree1)).to eq true
    expect(File.exist?(tree2)).to eq true

    druid2.rmdir
    expect(File.exist?(tree1)).to eq true
    expect(File.exist?(tree2)).to eq false

    druid1.rmdir
    expect(File.exist?(tree1)).to eq false
    expect(File.exist?(tree2)).to eq false
    expect(File.exist?(File.join(fixture_dir, 'cd'))).to eq false
  end

  describe 'alternate prefixes' do
    before :all do
      described_class.prefix = 'sulair'
    end

    after :all do
      described_class.prefix = 'druid'
    end

    it 'handles alternate prefixes' do
      expect { described_class.new('druid:cd456ef7890', fixture_dir) }.to raise_error(ArgumentError)
      expect(described_class.new('sulair:cd456ef7890', fixture_dir).id).to eq('cd456ef7890')
      expect(described_class.new('cd456ef7890', fixture_dir).druid).to eq('sulair:cd456ef7890')
    end
  end

  describe 'content directories' do
    it 'knows where its content goes' do
      druid = described_class.new(druid_str, fixture_dir)
      expect(druid.content_dir(false)).to eq(File.join(tree1, 'content'))
      expect(druid.metadata_dir(false)).to eq(File.join(tree1, 'metadata'))
      expect(druid.temp_dir(false)).to eq(File.join(tree1, 'temp'))

      expect(File.exist?(File.join(tree1, 'content'))).to eq false
      expect(File.exist?(File.join(tree1, 'metadata'))).to eq false
      expect(File.exist?(File.join(tree1, 'temp'))).to eq false
    end

    it 'creates its content directories on the fly' do
      druid = described_class.new(druid_str, fixture_dir)
      expect(druid.content_dir).to eq(File.join(tree1, 'content'))
      expect(druid.metadata_dir).to eq(File.join(tree1, 'metadata'))
      expect(druid.temp_dir).to eq(File.join(tree1, 'temp'))

      expect(File.exist?(File.join(tree1, 'content'))).to eq true
      expect(File.exist?(File.join(tree1, 'metadata'))).to eq true
      expect(File.exist?(File.join(tree1, 'temp'))).to eq true
    end

    it 'matches glob' do
      druid = described_class.new(druid_str, fixture_dir)
      druid.mkdir
      expect(Dir.glob(File.join(File.dirname(druid.path), described_class.glob)).size).to eq(1)
    end
    it 'matches strict_glob' do
      druid = described_class.new(druid_str, fixture_dir)
      druid.mkdir
      expect(Dir.glob(File.join(File.dirname(druid.path), described_class.strict_glob)).size).to eq(0)
      druid = described_class.new(strictly_valid_druid_str, fixture_dir)
      druid.mkdir
      expect(Dir.glob(File.join(File.dirname(druid.path), described_class.strict_glob)).size).to eq(1)
    end
  end

  describe 'content discovery' do
    let(:druid) { described_class.new(druid_str, fixture_dir) }
    let(:filelist) { %w[1 2 3 4].collect { |num| "someFile#{num}" } }

    it 'finds content in content directories' do
      location = druid.content_dir
      File.open(File.join(location, 'someContent'), 'w') { |f| f.write 'This is the content' }
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'finds content in the root directory' do
      location = druid.path(nil, true)
      File.open(File.join(location, 'someContent'), 'w') { |f| f.write 'This is the content' }
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'finds content in the leaf directory' do
      location = File.expand_path('..', druid.path(nil, true))
      File.open(File.join(location, 'someContent'), 'w') { |f| f.write 'This is the content' }
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'does not find content in the wrong content directory' do
      location = druid.metadata_dir
      File.open(File.join(location, 'someContent'), 'w') { |f| f.write 'This is the content' }
      expect(druid.find_content('someContent')).to be_nil
    end

    it 'does not find content in a higher-up directory' do
      location = File.expand_path('../..', druid.path(nil, true))
      File.open(File.join(location, 'someContent'), 'w') { |f| f.write 'This is the content' }
      expect(druid.find_content('someContent')).to be_nil
    end

    it 'finds a filelist in the content directory' do
      location = Pathname(druid.content_dir)
      filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(druid.find_filelist_parent('content', filelist)).to eq(location)
    end

    it 'finds a filelist in the root directory' do
      location = Pathname(druid.path(nil, true))
      filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(druid.find_filelist_parent('content', filelist)).to eq(location)
    end

    it 'finds a filelist in the leaf directory' do
      location = Pathname(File.expand_path('..', druid.path(nil, true)))
      filelist.each do |filename|
        location.join(filename).open('w') { |f| f.write "This is #{filename}" }
      end
      expect(druid.find_filelist_parent('content', filelist)).to eq(location)
    end

    it 'raises an exception if the first file in the filelist is not found' do
      Pathname(druid.content_dir)
      expect { druid.find_filelist_parent('content', filelist) }.to raise_exception(/content dir not found for 'someFile1' when searching/)
    end

    it 'raises an exception if any other file in the filelist is not found' do
      location = Pathname(druid.content_dir)
      location.join(filelist.first).open('w') { |f| f.write "This is #{filelist.first}" }
      expect { druid.find_filelist_parent('content', filelist) }.to raise_exception(/File 'someFile2' not found/)
    end
  end

  describe '#mkdir error handling' do
    it 'raises SameContentExistsError if the directory already exists' do
      druid_obj = described_class.new(strictly_valid_druid_str, fixture_dir)
      druid_obj.mkdir
      expect { druid_obj.mkdir }.to raise_error(DruidTools::SameContentExistsError)
    end

    it 'raises DifferentContentExistsError if a link already exists in the workspace for this druid' do
      source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(source_dir)
      dr = described_class.new(strictly_valid_druid_str, fixture_dir)
      dr.mkdir_with_final_link(source_dir)
      expect { dr.mkdir }.to raise_error(DruidTools::DifferentContentExistsError)
    end
  end

  describe '#mkdir_with_final_link' do
    let(:source_dir) { '/tmp/content_dir' }
    let(:druid_obj) { described_class.new(strictly_valid_druid_str, fixture_dir) }

    before do
      FileUtils.mkdir_p(source_dir)
    end

    it 'creates a druid tree in the workspace with the final directory being a link to the passed in source' do
      druid_obj.mkdir_with_final_link(source_dir)
      expect(File).to be_symlink(druid_obj.path)
      expect(File.readlink(tree2)).to eq(source_dir)
    end

    it 'does not error out if the link to source already exists' do
      druid_obj.mkdir_with_final_link(source_dir)
      expect(File).to be_symlink(druid_obj.path)
      expect(File.readlink(tree2)).to eq(source_dir)
    end

    it 'raises DifferentContentExistsError if a directory already exists in the workspace for this druid' do
      druid_obj.mkdir(fixture_dir)
      expect { druid_obj.mkdir_with_final_link(source_dir) }.to raise_error(DruidTools::DifferentContentExistsError)
    end
  end

  describe '#prune!' do
    let(:workspace) { Dir.mktmpdir }
    let(:dr1) { described_class.new(druid_str, workspace) }
    let(:dr2) { described_class.new(strictly_valid_druid_str, workspace) }
    let(:pathname1) { dr1.pathname }

    after do
      FileUtils.remove_entry workspace
    end

    it 'throws error on misconfig when base dir cannot be created' do
      dir = '/some/dir/that/does/not/exist' # we don't have permissions to create
      dr0 = described_class.new(druid_str, dir)
      expect { dr0.prune! }.to raise_error(StandardError)
      expect(File).not_to exist(dir)
    end

    it 'does not throw error when base can be created' do
      subdir = File.join(Dir.mktmpdir, 'some', 'nonexistant', 'subdir') # but this one *can* be created
      dr2 = described_class.new(strictly_valid_druid_str, subdir)
      expect { dr2.prune! }.not_to raise_error
      expect(File).to exist(subdir)
    end

    context 'when there is a shared ancestor' do
      before do
        # Nil the create records for this context because we're in a known read only one
        dr1.mkdir
        dr2.mkdir
        dr1.prune!
      end

      it 'deletes the outermost directory' do
        expect(File).not_to exist(dr1.path)
      end

      it 'deletes empty ancestor directories' do
        expect(File).not_to exist(pathname1.parent)
        expect(File).not_to exist(pathname1.parent.parent)
      end

      it 'stops at ancestor directories that have children' do
        # 'cd/456' should still exist because of druid2
        shared_ancestor = pathname1.parent.parent.parent
        expect(shared_ancestor.to_s).to match(%r{cd/456$})
        expect(File).to exist(shared_ancestor)
      end
    end

    it 'removes all directories up to the base path when there are no common ancestors' do
      # Make sure a delete record is not present
      expect(dr1).not_to be_deletes_record_exists

      # Nil the create records for this test
      dr1.mkdir
      dr1.prune!
      expect(File).not_to exist(File.join(workspace, 'cd'))
      expect(File).to exist(workspace)

      # Make sure a delete record was created
      expect(dr1).to be_deletes_dir_exists
      expect(dr1).to be_deletes_record_exists
    end

    it 'removes directories with symlinks' do
      # Make sure a delete record is not present
      expect(dr2).not_to be_deletes_record_exists

      # Nil the create records for this test
      source_dir = File.join workspace, 'src_dir'
      FileUtils.mkdir_p(source_dir)
      dr2.mkdir_with_final_link(source_dir)
      dr2.prune!
      expect(File).not_to exist(dr2.path)
      expect(File).not_to exist(File.join(workspace, 'cd'))

      # Make sure a delete record was created
      expect(dr2).to be_deletes_dir_exists
      expect(dr2).to be_deletes_record_exists
    end

    describe 'logging deleted druids' do
      # Purge any paths or delete records created in the test
      after do
        # Remove the .deletes dir to clean up
        dr2.deletes_delete_record if dr2.deletes_record_exists?
        FileUtils.rm_rf dr2.deletes_dir_pathname
      end

      it 'returns the path to the .deletes directory as a Pathname' do
        expect(dr2.deletes_dir_pathname.class).to eq(Pathname)
      end

      it 'returns the path to the delete record for a druid as a Pathname' do
        expect(dr2.deletes_record_pathname.class).to eq(Pathname)
      end

      it 'returns the path to the delete record for a druid as top_level/.deletes/druid' do
        expect(dr2.deletes_record_pathname.to_s).to eq("#{dr2.base}/.deletes/#{dr2.id}")
      end

      it 'returns false when the .deletes dir is not present on the file system' do
        expect(dr2).not_to be_deletes_dir_exists
      end

      it 'creates the .deletes dir and detect it exists' do
        # Clean the .deletes dir if present
        FileUtils.rm_rf dr2.deletes_dir_pathname

        # Test for exists? and create
        expect(dr2).not_to be_deletes_dir_exists
        dr2.create_deletes_dir
        expect(dr2).to be_deletes_dir_exists
      end

      it 'returns false when the .deletes dir does not have a deleted record for a druid' do
        expect(dr2).not_to be_deletes_record_exists
      end

      it 'creates a deleted record with a parent directory that has no .deletes directory and no deleted for the file and successfully create a delete record there' do
        # Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
        expect(dr2).not_to be_deletes_dir_exists
        expect(dr2).not_to be_deletes_record_exists

        # Create the delete record
        dr2.creates_delete_record

        # Check to ensure items were created
        expect(dr2).to be_deletes_dir_exists
        expect(dr2).to be_deletes_record_exists
      end

      it 'creates a delete record with a parent directory that has a .deletes directory that does not contain a delete record for this druid' do
        # Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
        expect(dr2).not_to be_deletes_dir_exists
        expect(dr2).not_to be_deletes_record_exists

        # Creates the deletes dir and check
        dr2.create_deletes_dir
        expect(dr2).to be_deletes_dir_exists
        expect(dr2).not_to be_deletes_record_exists

        # Create the delete record
        dr2.creates_delete_record

        # Check to ensure items were created
        expect(dr2).to be_deletes_dir_exists
        expect(dr2).to be_deletes_record_exists
      end

      it 'creates a delete record with a parent directory that does not have a .deletes directory and contains an older delete record' do
        # Expect there not to be a .deletes dir or file (the file expectation is redundant I know)
        expect(dr2).not_to be_deletes_dir_exists
        expect(dr2).not_to be_deletes_record_exists

        dr2.creates_delete_record
        time = Time.now
        expect(File.mtime(dr2.deletes_record_pathname)).to be <= time
        sleep(1) # force a one second pause in case the machine is fast, since mtime only goes down to the second

        dr2.creates_delete_record
        # Should have a new newer deleted record
        expect(File.mtime(dr2.deletes_record_pathname)).to be > time
      end
    end
  end
end
