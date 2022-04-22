# id3tag

Read and Write Mp3 metadata in crystal 
This is a very simple library without a rapper or anything
The raw methods and use cases are explained bellow
please don't hesitate to make an issue
I will fix as soon as possible 
ENJOY!!!

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     id3tag:
       github: h4ppyr0gu3/id3tag
   ```

2. Run `shards install`

## Usage

```crystal
require "id3tag"

file = File.open('path/to/file')
```

### Reading Tags

it is possible to read one or multiple tags
when it comes to picture tags, a new file is produced and spits out a filename

```crystal
Id3tag::Read.new(file).read_tag(<TAG_NAME_HERE>)
```

to read multiple tags 

```crystal
Id3tag::Read.new(file).read_tags
# returns an array of tag objects
```

### Writing Tags

```crystal
Id3tag::Write.new(file).overwrite(tag_hash, output_file_name)
```

### Tag Hash

key value pair where the 4 letters in caps are one of the following:

- APIC    [#sec4.15 Attached picture]
- COMM    [#sec4.11 Comments]
- COMR    [#sec4.25 Commercial frame]
- TALB    [#TALB Album/Movie/Show title]
- TBPM    [#TBPM BPM (beats per minute)]
- TCOM    [#TCOM Composer]
- TCON    [#TCON Content type]
- TCOP    [#TCOP Copyright message]
- TDAT    [#TDAT Date]
- TEXT    [#TEXT Lyricist/Text writer]
- TIT1    [#TIT1 Content group description]
- TIT2    [#TIT2 Title/songname/content description]
- TIT3    [#TIT3 Subtitle/Description refinement]
- TLAN    [#TLAN Language(s)]
- TLEN    [#TLEN Length]
- TOAL    [#TOAL Original album/movie/show title]
- TOFN    [#TOFN Original filename]
- TOLY    [#TOLY Original lyricist(s)/text writer(s)]
- TOPE    [#TOPE Original artist(s)/performer(s)]
- TORY    [#TORY Original release year]
- TPE1    [#TPE1 Lead performer(s)/Soloist(s)]
- TPE2    [#TPE2 Band/orchestra/accompaniment]
- TPE3    [#TPE3 Conductor/performer refinement]
- TPE4    [#TPE4 Interpreted, remixed, or otherwise modified by]
- TPOS    [#TPOS Part of a set]
- TPUB    [#TPUB Publisher]
- TRCK    [#TRCK Track number/Position in set]
- TSIZ    [#TSIZ Size]
- TSRC    [#TSRC ISRC (international standard recording code)]
- TSSE    [#TSEE Software/Hardware and settings used for encoding]
- TYER    [#TYER Year]
- TXXX    [#TXXX User defined text information frame]

*N.B.* an extensive list can be found on https://id3.org/id3v2.3.0#Declared_ID3v2_frames  
*N.B.* some are unsupported but if you would like them to be supported please create a PR and explain how you would intend for them to be used

```crystal
{
  "TIT2": "post malonef skfj",
  "TALB": "test",
  "TCOM": "composer",
  "TCON": "hip/hop",
  "APIC": "path/to/file.jpg",
}
```

## Contributing

1. Fork it (<https://github.com/your-github-user/id3tag/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [David Rogers](https://github.com/h4ppyr0gu3) - creator and maintainer
