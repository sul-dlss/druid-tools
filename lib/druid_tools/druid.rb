require 'pathname'

module DruidTools
  class Druid
    attr_accessor :druid, :base

    class << self
      attr_accessor :prefix

      # @return [Regexp] matches druid:aa111aa1111 or aa111aa1111
      def pattern
        /\A(?:#{self.prefix}:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
      end

      # @return [String] suitable for use in [Dir#glob]
      def glob
        "{#{self.prefix}:,}[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]"
      end

      # @param [String] druid id
      # @return [Boolean] true if druid matches pattern; otherwise false
      def valid?(druid)
        return druid =~ pattern ? true : false
      end

    end
    self.prefix = 'druid'

    [:content, :metadata, :temp].each do |dir_type|
      self.class_eval <<-EOC
        def #{dir_type}_dir(create=true)
          path("#{dir_type}",create)
        end

        def find_#{dir_type}(path)
          find(:#{dir_type},path)
        end
      EOC
    end

    # @param druid [String] A valid druid
    # @param base [String] The directory used by #path
    def initialize(druid, base='.')
      druid = druid.to_s unless druid.is_a? String
      unless self.class.valid?(druid)
        raise ArgumentError, "Invalid DRUID: '#{druid}'"
      end
      druid = [self.class.prefix,druid].join(':') unless druid =~ /^#{self.class.prefix}:/
      @base = base
      @druid = druid
    end

    def id
      @druid.scan(self.class.pattern).flatten.join('')
    end

    def tree
      @druid.scan(self.class.pattern).flatten + [id]
    end

    def path(extra=nil, create=false)
      result = File.join(*([base,tree,extra].compact))
      mkdir(extra) if create and not File.exists?(result)
      result
    end

    def mkdir(extra=nil)
      new_path = path(extra)
      if(File.symlink? new_path)
        raise DruidTools::DifferentContentExistsError, "Unable to create directory, link already exists: #{new_path}"
      end
      if(File.directory? new_path)
        raise DruidTools::SameContentExistsError, "The directory already exists: #{new_path}"
      end
      FileUtils.mkdir_p(new_path)
    end

    def find(type, path)
      possibles = [self.path(type.to_s),self.path,File.expand_path('..',self.path)]
      loc = possibles.find { |p| File.exists?(File.join(p,path)) }
      loc.nil? ? nil : File.join(loc,path)
    end

    # @param [String] type The type of directory being sought ('content', 'metadata', or 'temp')
    # @param [Array<String>,String] filelist The files that are expected to be present in the directory
    # @return [Pathname] Search for and return the pathname of the directory that contains the list of files.
    #    Raises an exception unless a directory is found that contains all the files in the list.
    def find_filelist_parent(type, filelist)
      raise "File list not specified" if filelist.nil? or filelist.empty?
      filelist = [filelist] unless filelist.is_a?(Array)
      search_dir = Pathname(self.path(type))
      directories = [search_dir, search_dir.parent, search_dir.parent.parent]
      found_dir = directories.find { |pathname| pathname.join(filelist[0]).exist? }
      raise "#{type} dir not found for '#{filelist[0]}' when searching '#{search_dir}'" if found_dir.nil?
      filelist.each do |filename|
        raise "File '#{filename}' not found in #{type} dir s'#{found_dir}'" unless found_dir.join(filename).exist?
      end
      found_dir
    end

    def mkdir_with_final_link(source, extra=nil)
      new_path = path(extra)
      if(File.directory?(new_path) && !File.symlink?(new_path))
        raise DruidTools::DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}"
      end
      real_path = File.expand_path('..',new_path)
      FileUtils.mkdir_p(real_path)
      FileUtils.ln_s(source, new_path, :force=>true)
    end

    def rmdir(extra=nil)
      parts = tree
      parts << extra unless extra.nil?
      while parts.length > 0
        dir = File.join(base, *parts)
        begin
          FileUtils.rm(File.join(dir,'.DS_Store'), :force => true)
          FileUtils.rmdir(dir)
        rescue Errno::ENOTEMPTY
          break
        end
        parts.pop
      end
    end

    def pathname
      Pathname self.path
    end

    def base_pathname
      Pathname self.base
    end

    def prune!
      this_path = pathname
      parent = this_path.parent
      parent.rmtree if parent.exist? && parent != base_pathname
      prune_ancestors parent.parent
    end

    # @param [Pathname] outermost_branch The branch at which pruning begins
    # @return [void] Ascend the druid tree and prune empty branches
    def prune_ancestors(outermost_branch)
      while outermost_branch.children.size == 0
        outermost_branch.rmdir
        outermost_branch = outermost_branch.parent
        break if  outermost_branch == base_pathname
      end
    rescue
    end

  end
end
