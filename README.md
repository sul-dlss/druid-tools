[![CircleCI](https://circleci.com/gh/sul-dlss/druid-tools/tree/main.svg?style=svg)](https://circleci.com/gh/sul-dlss/druid-tools/tree/main)
[![Gem Version](https://badge.fury.io/rb/druid-tools.svg)](https://badge.fury.io/rb/druid-tools)
[![codecov](https://codecov.io/github/sul-dlss/druid-tools/graph/badge.svg?token=1KZ423kSwj)](https://codecov.io/github/sul-dlss/druid-tools)

# Druid::Tools

Tools to manipulate DRUID trees and content directories

Note that druid syntax is defined in consul (and druids are issued by the SURI service).  See https://consul.stanford.edu/pages/viewpage.action?title=SURI+2.0+Specification&spaceKey=chimera

Druid format:

    bbdddbbdddd (two letters three digits two letters 4 digits)

Letters must be lowercase, and must not include A, E, I, O, U or L.  (capitals for easier distinction here)
We often use vowels in our test data, and this code base has allowed vowels historically (though not
uppercase).  We now recommend setting the strict argument to true whenever using this code to build
DruidTools::Druid objects or to validate druid identifier strings.

## Usage

### with strict argument

```ruby
d = DruidTools::Druid.new('druid:ab123cd4567', '/dor/workspace', true) # no aeioul
=> ArgumentError: Invalid DRUID: 'druid:ab123cd4567'
d = DruidTools::Druid.new('druid:bb123cd4567', '/dor/workspace', true)
d.druid
=> "druid:bb123cd4567"
```

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
d = DruidTools::Druid.valid?('druid:ab123cd4567', true) # strict validation: no aeioul
=> false
d = DruidTools::Druid.valid?('druid:ab123cd4567', false)
=> true
d = DruidTools::Druid.valid?('druid:bb123cd4567', true)
=> true

```

### Manipulate directories and symlinks

```ruby
# Make the druid tree
d.mkdir
# Make a directory within the druid triee
d.mkdir('temp')
# Remove a druid tree, but only up to the last shared branch directory
d.rmdir
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

### Stacks and Purl compatible Druid.  All files at the leaf directories

```ruby
pd = DruidTools::PurlDruid.new('druid:ab123cd4567', '/purl')
pd.path
=> "/purl/ab/123/cd/4567"
pd.content_dir
=> "/purl/ab/123/cd/4567"
```
