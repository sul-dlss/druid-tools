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

- <b>0.1.0</b> - Additional support for alternate content locations
- <b>0.0.1</b> - Initial Release 