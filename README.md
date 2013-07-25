# Druid::Tools

## Usage

### Get attributes and paths

  d = DruidTools.new('druid:ab123cd4567', '/dor/workspace')
	d.druid
	=> "druid:ab123cd4567"
	d.id
	=> "ab123cd4567"
	d.path
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567"
	d.path('content/my_file.jpg')
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/content/my_file.jpg"

### Check whether a druid is valid

  d = DruidTools::Druid.valid?('druid:ab123cd4567')
	=> true
  d = DruidTools::Druid.valid?('blah')
	=> false

### Manipulate directories and symlinks

	# Make the druid tree
	d.mkdir
	# Make a directory within the druid triee
	d.mkdir('temp')
	# Remove a druid tree, but only up to the last shared branch directory
	d.rmdir
	# Link content from another source into a druid tree
	d.mkdir_with_final_link('/some/other/content/location')
	
### Content-specific methods create the relevant directories if they don't exist

Pass `false` as a parameter to prevent directory creation.

	d.content_dir
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/content"
	d.metadata_dir
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/metadata"
	d.temp_dir
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/temp"
	
### Locate existing content within the druid tree

	# In the correct directory
	d.find_metadata('contentMetadata.xml')
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/metadata/contentMetadata.xml"
	
	# In other known previous locations, for backward compatibility
	d.find_metadata('contentMetadata.xml')
	=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/contentMetadata.xml"

	d.find_metadata('contentMetadata.xml')
	=> "/dor/workspace/ab/123/cd/4567/contentMetadata.xml"
	
	d.find_content('this/file/does/not/exist.jpg')
	=> nil
	
## History

- <b>0.2.5</b> - Added glob pattern as DruidTools::Druid.glob
- <b>0.2.4</b> - Allow non-String as .new parameter and added InvalidDruidError
- <b>0.2.3</b> - Fine tune behavior of find_filelist_parent
- <b>0.2.2</b> - Added find_filelist_parent method allowing search for a set of files
- <b>0.2.1</b> - Do not error out during symlink creation if it already exists
- <b>0.2.0</b> - Added DruidTools::Druid.valid?
- <b>0.1.0</b> - Additional support for alternate content locations
- <b>0.0.1</b> - Initial Release 
