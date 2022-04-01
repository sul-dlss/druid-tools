# frozen_string_literal: true

RSpec.describe DruidTools::Druid do
  let(:fixture_dir) { File.expand_path('fixtures', __dir__) }
  let(:druid_str) { 'druid:cd456ef7890' }
  let(:tree1) { File.join(fixture_dir, 'cd/456/ef/7890/cd456ef7890') }
  let(:strictly_valid_druid_str) { 'druid:cd456gh1234' }
  let(:tree2) { File.join(fixture_dir, 'cd/456/gh/1234/cd456gh1234') }
  let(:access_druid_str) { 'druid:cd456ef9999' }
  let(:tree3) { File.join(fixture_dir, 'cd/456/ef/9999') }

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

  describe '#pruning_base' do
    subject(:path) { described_class.new(druid_str).pruning_base }

    it { is_expected.to eq(Pathname.new('./cd/456/ef/7890')) }
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

  it '#mkdir creates, and #rmdir destroys, *only* the expected druid directory' do
    allow(Deprecation).to receive(:warn)
    expect(File.exist?(tree1)).to be false
    expect(File.exist?(tree2)).to be false
    expect(File.exist?(tree3)).to be false

    druid1 = described_class.new(druid_str, fixture_dir)
    druid2 = described_class.new(strictly_valid_druid_str, fixture_dir)
    druid3 = DruidTools::AccessDruid.new(access_druid_str, fixture_dir)

    druid1.mkdir
    expect(File.exist?(tree1)).to be true
    expect(File.exist?(tree2)).to be false
    expect(File.exist?(tree3)).to be false

    druid2.mkdir
    expect(File.exist?(tree1)).to be true
    expect(File.exist?(tree2)).to be true
    expect(File.exist?(tree3)).to be false

    druid3.mkdir
    expect(File.exist?(tree1)).to be true
    expect(File.exist?(tree2)).to be true
    expect(File.exist?(tree3)).to be true

    druid3.rmdir
    expect(File.exist?(tree1)).to be true
    expect(File.exist?(tree2)).to be true
    expect(File.exist?(tree3)).to be false

    druid2.rmdir
    expect(File.exist?(tree1)).to be true
    expect(File.exist?(tree2)).to be false
    expect(File.exist?(tree3)).to be false

    druid1.rmdir
    expect(File.exist?(tree1)).to be false
    expect(File.exist?(tree2)).to be false
    expect(File.exist?(tree3)).to be false
    expect(File.exist?(File.join(fixture_dir, 'cd'))).to be false
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

      expect(File.exist?(File.join(tree1, 'content'))).to be false
      expect(File.exist?(File.join(tree1, 'metadata'))).to be false
      expect(File.exist?(File.join(tree1, 'temp'))).to be false
    end

    it 'creates its content directories on the fly' do
      druid = described_class.new(druid_str, fixture_dir)
      expect(druid.content_dir).to eq(File.join(tree1, 'content'))
      expect(druid.metadata_dir).to eq(File.join(tree1, 'metadata'))
      expect(druid.temp_dir).to eq(File.join(tree1, 'temp'))

      expect(File.exist?(File.join(tree1, 'content'))).to be true
      expect(File.exist?(File.join(tree1, 'metadata'))).to be true
      expect(File.exist?(File.join(tree1, 'temp'))).to be true
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
      File.write(File.join(location, 'someContent'), 'This is the content')
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'finds content in the root directory' do
      location = druid.path(nil, true)
      File.write(File.join(location, 'someContent'), 'This is the content')
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'finds content in the leaf directory' do
      location = File.expand_path('..', druid.path(nil, true))
      File.write(File.join(location, 'someContent'), 'This is the content')
      expect(druid.find_content('someContent')).to eq(File.join(location, 'someContent'))
    end

    it 'does not find content in the wrong content directory' do
      location = druid.metadata_dir
      File.write(File.join(location, 'someContent'), 'This is the content')
      expect(druid.find_content('someContent')).to be_nil
    end

    it 'does not find content in a higher-up directory' do
      location = File.expand_path('../..', druid.path(nil, true))
      File.write(File.join(location, 'someContent'), 'This is the content')
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
      new_path = dr.path
      FileUtils.mkdir_p(File.expand_path('..', new_path))
      FileUtils.ln_s(source_dir, new_path, force: true)

      expect { dr.mkdir }.to raise_error(DruidTools::DifferentContentExistsError)
    end
  end

  describe '#mkdir_with_final_link' do
    let(:source_dir) { '/tmp/content_dir' }
    let(:druid_obj) { described_class.new(strictly_valid_druid_str, fixture_dir) }

    before do
      allow(Deprecation).to receive(:warn)
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
    let(:dr3) { DruidTools::AccessDruid.new(access_druid_str, workspace) }
    let(:pathname1) { dr1.pathname }

    before do
      allow(Deprecation).to receive(:warn)
    end

    after do
      FileUtils.remove_entry workspace
    end

    context 'with an access druid sharing the first three path segments' do
      before do
        # Nil the create records for this context because we're in a known read only one
        dr1.mkdir
        dr2.mkdir
        dr3.mkdir
        dr3.prune!
      end

      it 'deletes the outermost directory' do
        expect(File).not_to exist(dr3.pruning_base)
      end

      it 'does not delete unrelated ancestor directories' do
        expect(File).to exist(dr1.pruning_base)
        expect(File).to exist(dr1.pruning_base.parent)
      end

      it 'stops at ancestor directories that have children' do
        # 'cd/456/ef' should still exist because of dr1
        shared_ancestor = dr1.pruning_base.parent
        expect(shared_ancestor.to_s).to match(%r{cd/456/ef$})
        expect(File).to exist(shared_ancestor)
      end
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
      # Nil the create records for this test
      dr1.mkdir
      dr1.prune!
      expect(File).not_to exist(File.join(workspace, 'cd'))
      expect(File).to exist(workspace)
    end

    it 'removes directories with symlinks' do
      # Nil the create records for this test
      source_dir = File.join workspace, 'src_dir'
      FileUtils.mkdir_p(source_dir)
      dr2.mkdir_with_final_link(source_dir)
      dr2.prune!
      expect(File).not_to exist(dr2.path)
      expect(File).not_to exist(File.join(workspace, 'cd'))
    end
  end
end
