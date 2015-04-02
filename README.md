# Druid::Tools

Tools to manipulate DRUID trees and content directories

## Usage

### Get attributes and paths

```ruby
d = DruidTools::Druid.new('druid:ab123cd4567', '/dor/workspace')
d.druid
=> "druid:ab123cd4567"
d.id
=> "ab123cd4567"
d.path
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567"
d.content_dir
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/content"
d.path('content/my_file.jpg')
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/content/my_file.jpg"
```

### Check whether a druid is valid

```ruby
d = DruidTools::Druid.valid?('druid:ab123cd4567')
=> true
d = DruidTools::Druid.valid?('blah')
=> false
```

### Manipulate directories and symlinks

```ruby
# Make the druid tree
d.mkdir
# Make a directory within the druid triee
d.mkdir('temp')
# Remove a druid tree, but only up to the last shared branch directory
d.rmdir
# Link content from another source into a druid tree
d.mkdir_with_final_link('/some/other/content/location')
```

### Content-specific methods create the relevant directories if they don't exist

Pass `false` as a parameter to prevent directory creation, or `true` (default) to create directories.

```ruby
d.content_dir(false)
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/content"
File.directory?(d.content_dir(false))
=> false
File.directory?(d.content_dir)
=> true
d.metadata_dir(false)
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/metadata"
d.temp_dir(false)
=> "/dor/workspace/ab/123/cd/4567/ab123cd4567/temp"
```

### Locate existing content within the druid tree

```ruby
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
```

### Pruning: removes leaves of tree up to non-empty branches

```ruby
d1 = DruidTools::Druid.new 'druid:cd456ef7890', '/workspace'
d1.mkdir
d2 = DruidTools::Druid.new 'druid:cd456gh1234', '/workspace'
d2.mkdir

# /workspace/cd/456/gh/1234/cd456gh1234 pruned down to /workspace/cd/456
# /workspace/cd/456/ef/7890/cd456ef7890 left intact
d2.prune!
```

### Stacks and Purl compatible Druid.  All files at the leaf directories

```ruby
pd = DruidTools::PurlDruid.new 'druid:ab123cd4567', '/purl'
pd.path
=> "/purl/ab/123/cd/4567"
pd.content_dir
=> "/purl/ab/123/cd/4567"
```

### History

- <b>0.3.0</b> - Added #prune method. Added AccessDruid for stacks and purl access
- <b>0.2.6</b> - Fixed VERSION warning message, and documentation cleanup
- <b>0.2.5</b> - Added glob pattern as DruidTools::Druid.glob
- <b>0.2.4</b> - Allow non-String as .new parameter and added InvalidDruidError
- <b>0.2.3</b> - Fine tune behavior of find_filelist_parent
- <b>0.2.2</b> - Added find_filelist_parent method allowing search for a set of files
- <b>0.2.1</b> - Do not error out during symlink creation if it already exists
- <b>0.2.0</b> - Added DruidTools::Druid.valid?
- <b>0.1.0</b> - Additional support for alternate content locations
- <b>0.0.1</b> - Initial Release
