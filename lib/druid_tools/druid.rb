module DruidTools
  class Druid
    attr_accessor :druid, :base
    
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
    
    DRUID_PATTERN = /^(?:druid:)?([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/
    def initialize(druid,base='.')
      if druid !~ DRUID_PATTERN
        raise ArgumentError, "Invalid DRUID: #{druid}"
      end
      @base = base
      @druid = druid
    end
  
    def id
      @druid.scan(/^(?:druid:)?(.+)$/).flatten.last
    end
  
    def tree
      @druid.scan(DRUID_PATTERN).flatten + [id]
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
      possibles = [self.path(type.to_s),self.path]
      loc = possibles.find { |p| File.exists?(File.join(p,path)) }
      loc.nil? ? nil : File.join(loc,path)
    end
    
    def mkdir_with_final_link(source, extra=nil)
      new_path = path(extra)
      if(File.symlink? new_path)
        raise DruidTools::SameContentExistsError, "The link already exists: #{new_path}"
      end
      if(File.directory? new_path)
        raise DruidTools::DifferentContentExistsError, "Unable to create link, directory already exists: #{new_path}"
      end
      real_dirs = tree
      real_dirs.slice!(real_dirs.length - 1)
      real_path = File.join(base, real_dirs)
      FileUtils.mkdir_p(real_path)
      FileUtils.ln_s(source, new_path)
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
  end
end
