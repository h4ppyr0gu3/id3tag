module Id3tag
  class Read < Base
    def initialize(file : File)
      super
      @tags = read_tags
    end

    InvalidIDType = Exception.new("Not valid ID3v2 tag")

    TEXT_TAGS = %w(
      COMM COMR ENCR EQUA ETCO GEOB GRID IPLS LINK MCDI MLLT OWNE PRIV PCNT POPM POSS
      RBUF RVAD RVRB SYLT SYTC TALB TBPM TCOM TCON TCOP TDAT TDLY TENC TEXT TFLT TIME
      TIT1 TIT2 TIT3 TKEY TLAN TLEN TMED TOAL TOFN TOLY TOPE TORY TOWN TPE1 TPE2 TPE3
      TPE4 TPOS TPUB TRCK TRDA TRSN TRSO TSIZ TSRC TSSE TYER TXXX UFID USER USLT WCOM
      WCOP WOAF WOAR WOAS WORS WPAY WPUB WXXX
    )

    def read_all_metadata
      raise InvalidIDType unless validate_header
      # @tags.dup.each do |tag|
      #
      #   # yield tag
      # end
    end

    def validate_header
      count = 0
      @file.pos = 0
      char_array = Array(Char).new
      @file.each_char do |bytes|
        char_array << bytes
        count += 1
        if count == 3
          break
        end
      end
      @file.pos = 0
      return false if char_array.join != "ID3"
      true
    end

    def reset_file
      @file.pos = 0
    end

    def read_tag(tag_type)
      @tags.map do |tag|
        return tag.value if tag.name == tag_type
      end
    end

    def read_tags
      tags = Array(Tag).new
      header_size = header_size(@file)
      start_val = 10
      while start_val < header_size
        tag = Tag.new
        tag.name = read_tag_title(start_val, @file)
        if tag.name == "\u0000\u0000\u0000\u0000"
          return tags
        end
        if TEXT_TAGS.includes?(tag.name)
          read_text_tags(tag, start_val, @file)
        elsif tag.name == "APIC"
          read_picture_tag(tag, start_val, @file)
        else
          tag.size = read_tag_size(start_val, @file)
        end
        start_val += tag.size + 10
        tags << tag
      end
      tags
    end

    def read_picture_tag(tag, start_val, @file)
      tag.size = read_tag_size(start_val, @file)
      mime_type = read_mime_type(start_val + 11, @file)
      mime_size = mime_type.size
      description = read_description(@file, start_val, mime_size)
      desc_length = description.size
      if unicode?(start_val, @file)
        description.gsub("\u0000", "")
      end
      offset = mime_size + 1 + 6 + 2 + desc_length + 1
      @file.pos = 0
      pos = start_val + 10 + offset
      output_filename = "#{UUID.random}.#{mime_type}"
      @file.read_at(pos, tag.size - offset) do |bytes|
        # ameba:disable Lint/UselessAssign
        File.write(output_filename, bytes, perm = PERMS, mode = "wb")
        # ameba:enable Lint/UselessAssign
      end
      tag.value = output_filename
    end

    def read_description(file, start_val, mime_size)
      pos = start_val + mime_size + 11 + 6 + 2
      original = pos
      count = 0; prev_byte = 0
      description = ""
      loop do
        file.read_at(pos, 1) do |bytes|
          bytes.each_byte do |byte|
            if byte == prev_byte
              file.read_at(original, count) do |ibytes|
                description = ibytes.read_string(count)
              end
              return description
            end
            pos += 1; count += 1
          end
        end
      end
    end

    def read_text_tags(tag, start_val, header)
      tag.size = read_tag_size(start_val, header)
      if unicode?(start_val, header)
        tag.value = read_utf8_tag_value(start_val, header, tag.size)
      else
        tag.value = read_tag_value(start_val, header, tag.size)
      end
    end

    def read_mime_type(start, file : File)
      char_array = Array(Char).new
      file.read_at(start, 10) do |bytes|
        bytes.each_char do |char|
          char_array << char
        end
      end
      char_array.delete('\u0000')
      char_array.join.gsub("image/", "")
    end

    def unicode?(start, header)
      header.read_at(start + 10, 1) do |bytes|
        bytes.each_byte do |byte|
          return false if byte == 0
          return true if byte == 1
          return false
        end
      end
    end

    def read_utf8_tag_value(start : UInt8 | Int32, header : File, size : UInt8 | Int32)
      header.read_at(start + 13, size - 3) do |bytes|
        return bytes.read_string(size - 3).gsub("\u0000", "")
      end
    end

    def read_tag_title(start : UInt8 | Int32, header : File)
      tag_name = Array(Char | String).new
      header.read_at(start, 4) do |bytes|
        bytes.each_char do |byte|
          tag_name << byte
        end
      end
      tag = tag_name.join("")
      tag
    end

    def read_tag_size(start : UInt8 | Int32, header : File)
      tag_size = Array(BitArray).new
      header.read_at(start + 4, 4) do |bytes|
        bytes.each_byte do |byte|
          tag_size << int_to_bit_array(byte)
        end
      end
      bit_array_size = join_bit_array(tag_size, 32)
      size = binary_to_int(bit_array_size.reverse!)
      size
    end

    def read_tag_value(start : UInt8 | Int32, header : File, length : UInt8 | Int32)
      tag_name = Array(Char | String).new
      header.read_at(start + 11, length - 2) do |bytes|
        bytes.each_char do |byte|
          tag_name << byte
        end
      end
      tag = tag_name.join("").gsub("\u0000", " ")
      tag
    end
  end
end
