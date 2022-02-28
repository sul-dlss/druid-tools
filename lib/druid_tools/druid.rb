# frozen_string_literal: true

require 'pathname'
require 'fileutils'
require 'deprecation'

module DruidTools
  class Druid
    extend Deprecation
    self.deprecation_horizon = 'druid-tools 3.0.0'

    attr_accessor :druid, :base

    # See https://consul.stanford.edu/pages/viewpage.action?title=SURI+2.0+Specification&spaceKey=chimera
    # character class matching allowed letters in a druid suitable for use in regex (no aeioul)
    STRICT_LET = '[b-df-hjkmnp-tv-z]'

    class << self
      attr_accessor :prefix

      # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
      # @return [Regexp] matches druid:aa111aa1111 or aa111aa1111
      def pattern(strict = false)
        return /\A(?:#{prefix}:)?(#{STRICT_LET}{2})(\d{3})(#{STRICT_LET}{2})(\d{4})\z/ if strict

        /\A(?:#{prefix}:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
      end

      # @return [String] suitable for use in [Dir#glob]
      def glob
        "{#{prefix}:,}[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]"
      end

      # @return [String] suitable for use in [Dir#glob]
      def strict_glob
        "{#{prefix}:,}#{STRICT_LET}#{STRICT_LET}[0-9][0-9][0-9]#{STRICT_LET}#{STRICT_LET}[0-9][0-9][0-9][0-9]"
      end

      # @param [String] druid id
      # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
      # @return [Boolean] true if druid matches pattern; otherwise false
      def valid?(druid, strict = false)
        druid =~ pattern(strict) ? true : false
      end
    end
    self.prefix = 'druid'

    def content_dir(create = true)
      path('content', create)
    end

    def metadata_dir(create = true)
      path('metadata', create)
    end

    def temp_dir(create = true)
      path('temp', create)
    end

    def find_content(path)
      find(:content, path)
    end

    def find_metadata(path)
      find(:metadata, path)
    end

    def find_temp(path)
      find(:temp, path)
    end

    # @param druid [String] A valid druid
    # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
    # @param base [String] The directory used by #path
    def initialize(druid, base = '.', strict = false)
      druid = druid.to_s unless druid.is_a? String
      raise ArgumentError, "Invalid DRUID: '#{druid}'" unless self.class.valid?(druid, strict)

      druid = [self.class.prefix, druid].join(':') unless druid =~ /^#{self.class.prefix}:/
      @base = base
      @druid = druid
    end

    def id
      @druid.scan(self.class.pattern).flatten.join
    end

    def tree
      @druid.scan(self.class.pattern).flatten + [id]
    end

    def path(extra = nil, create = false)
      result = File.join(*[base, tree, extra].compact)
      mkdir(extra) if create && !File.exist?(result)
      result
    end

    def mkdir(extra = nil)
      new_path = path(extra)
      raise DruidTools::DifferentContentExistsError, "Unable to create directory, link already exists: #{new_path}" if File.symlink? new_path
      raise DruidTools::SameContentExistsError, "The directory already exists: #{new_path}" if File.directory? new_path

      FileUtils.mkdir_p(new_path)
    end

    def find(type, path)
      possibles = [self.path(type.to_s), self.path, File.expand_path('..', self.path)]
      loc = possibles.find { |p| File.exist?(File.join(p, path)) }
      loc.nil? ? nil : File.join(loc, path)
    end

    # @param [String] type The type of directory being sought ('content', 'metadata', or 'temp')
    # @param [Array<String>,String] filelist The files that are expected to be present in the directory
    # @return [Pathname] Search for and return the pathname of the directory that contains the list of files.
    #    Raises an exception unless a directory is found that contains all the files in the list.
    def find_filelist_parent(type, filelist)
      raise 'File list not specified' if filelist.nil? || filelist.empty?

      filelist = [filelist] unless filelist.is_a?(Array)
      search_dir = Pathname(path(type))
      directories = [search_dir, search_dir.parent, search_dir.parent.parent]
      found_dir = directories.find { |pathname| pathname.join(filelist[0]).exist? }
      raise "#{type} dir not found for '#{filelist[0]}' when searching '#{search_dir}'" if found_dir.nil?

      filelist.each do |filename|
        raise "File '#{filename}' not found in #{type} dir '#{found_dir}'" unless found_dir.join(filename).exist?
      end
      found_dir
    end

    def mkdir_with_final_link(source, extra = nil)
      new_path = path(extra)
      if File.directory?(new_path) && !File.symlink?(new_path)
        raise DruidTools::DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}"
      end

      real_path = File.expand_path('..', new_path)
      FileUtils.mkdir_p(real_path)
      FileUtils.ln_s(source, new_path, force: true)
    end
    deprecation_deprecate :mkdir_with_final_link

    def rmdir(extra = nil)
      parts = tree
      parts << extra unless extra.nil?
      until parts.empty?
        dir = File.join(base, *parts)
        begin
          FileUtils.rm(File.join(dir, '.DS_Store'), force: true)
          FileUtils.rmdir(dir)
        rescue Errno::ENOTEMPTY
          break
        end
        parts.pop
      end
    end
    deprecation_deprecate :rmdir

    def pathname
      Pathname path
    end

    def base_pathname
      Pathname base
    end

    def prune!
      this_path = pathname
      parent = this_path.parent
      parent.rmtree if parent.exist? && parent != base_pathname
      prune_ancestors parent.parent
    end
    deprecation_deprecate :prune!

    # @param [Pathname] outermost_branch The branch at which pruning begins
    # @return [void] Ascend the druid tree and prune empty branches
    def prune_ancestors(outermost_branch)
      while outermost_branch.exist? && outermost_branch.children.empty?
        outermost_branch.rmdir
        outermost_branch = outermost_branch.parent
        break if outermost_branch == base_pathname
      end
    end
    deprecation_deprecate :prune_ancestors
  end
end
