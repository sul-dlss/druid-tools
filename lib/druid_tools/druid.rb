require 'pathname'
require 'fileutils'

module DruidTools
  class Druid
    @@deletes_directory_name = '.deletes'
    attr_accessor :druid, :base

    # See https://consul.stanford.edu/pages/viewpage.action?title=SURI+2.0+Specification&spaceKey=chimera
    # character class matching allowed letters in a druid suitable for use in regex (no aeioul)
    STRICT_LET = '[b-df-hjkmnp-tv-z]'.freeze

    class << self
      attr_accessor :prefix

      # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
      # @return [Regexp] matches druid:aa111aa1111 or aa111aa1111
      def pattern(strict=false)
        return /\A(?:#{self.prefix}:)?(#{STRICT_LET}{2})(\d{3})(#{STRICT_LET}{2})(\d{4})\z/ if strict
        /\A(?:#{self.prefix}:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})\z/
      end

      # @return [String] suitable for use in [Dir#glob]
      def glob
        "{#{self.prefix}:,}[a-z][a-z][0-9][0-9][0-9][a-z][a-z][0-9][0-9][0-9][0-9]"
      end

      # @return [String] suitable for use in [Dir#glob]
      def strict_glob
        "{#{self.prefix}:,}#{STRICT_LET}#{STRICT_LET}[0-9][0-9][0-9]#{STRICT_LET}#{STRICT_LET}[0-9][0-9][0-9][0-9]"
      end

      # @param [String] druid id
      # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
      # @return [Boolean] true if druid matches pattern; otherwise false
      def valid?(druid, strict=false)
        druid =~ pattern(strict) ? true : false
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
    # @param [boolean] true if validation should be more restrictive about allowed letters (no aeioul)
    # @param base [String] The directory used by #path
    def initialize(druid, base='.', strict=false)
      druid = druid.to_s unless druid.is_a? String
      unless self.class.valid?(druid, strict)
        raise ArgumentError, "Invalid DRUID: '#{druid}'"
      end
      druid = [self.class.prefix, druid].join(':') unless druid =~ /^#{self.class.prefix}:/
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
        raise "File '#{filename}' not found in #{type} dir '#{found_dir}'" unless found_dir.join(filename).exist?
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
      creates_delete_record
    end

    #This function checks for existance of a .deletes dir one level into the path (ex: stacks/.deletes or purl/.deletes).
    #If the directory does not exist, it is created.  If the directory exists, check to see if the current druid has an entry there, if it does delete it.
    #This is done because a file might be deleted, then republishing, then deleted we again, and we want to log the most recent delete.
    #
    #@raises [Errno::EACCES] If write priveleges are denied
    #
    #@return [void]
    def prep_deletes_dir
      #Check for existences of deletes dir
      create_deletes_dir if !deletes_dir_exists?
      #In theory we could return true after this step (if it fires), since if there was no deletes dir then the file can't be present in the dir

      #Check to see if this druid has been deleted before, meaning file currently exists
      deletes_delete_record if deletes_record_exists?
    end

    #Provide the location for the .deletes directory in the tree
    #
    #@return [Pathname] the path to the directory, ex: "stacks/.deletes"
    def deletes_dir_pathname
      return Pathname(self.base.to_s + (File::SEPARATOR+@@deletes_directory_name))
    end

    def deletes_record_pathname
      return Pathname(deletes_dir_pathname.to_s + File::SEPARATOR + self.id)
    end

    #Using the deletes directory path supplied by deletes_dir_pathname, this function determines if this directory exists
    #
    #@return [Boolean] true if if exists, false if it does not
    def deletes_dir_exists?
      return File.directory?(deletes_dir_pathname)
    end

    def deletes_record_exists?
      return File.exists?(deletes_dir_pathname.to_s + File::SEPARATOR + self.id)
    end

    #Creates the deletes dir using the path supplied by deletes_dir_pathname
    #
    #@raises [Errno::EACCES] If write priveleges are denied
    #
    #@return [void]
    def create_deletes_dir
      FileUtils::mkdir_p deletes_dir_pathname
    end

    #Deletes the delete record if it currently exists.  This is done to change the filed created, not just last modified time, on the system
    #
    #@raises [Errno::EACCES] If write priveleges are denied
    #
    #return [void]
    def deletes_delete_record
      FileUtils.rm(deletes_record_pathname) if deletes_record_exists? #thrown in to prevent an  Errno::ENOENT if you call this on something without a delete record
    end

    #Creates an empty (pointer) file using the object's id in the .deletes dir
    #
    #@raises [Errno::EACCES] If write priveleges are denied
    #
    #@return [void]
    def creates_delete_record
      prep_deletes_dir
      FileUtils.touch(deletes_record_pathname)
    end

    # @param [Pathname] outermost_branch The branch at which pruning begins
    # @return [void] Ascend the druid tree and prune empty branches
    def prune_ancestors(outermost_branch)
      while outermost_branch.exist? && outermost_branch.children.size == 0
        outermost_branch.rmdir
        outermost_branch = outermost_branch.parent
        break if  outermost_branch == base_pathname
      end
    end

  end
end
