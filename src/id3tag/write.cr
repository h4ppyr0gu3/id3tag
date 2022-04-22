module Id3tag
  class Write < Base
    InvalidTag          = Exception.new("Tag name is not supported")
    UnsupportedMimeType = Exception.new("Mime type is unsupported at the moment")
    PERMS               = File::Permissions.new(0o600)
    NULLBYTE_COUNT      = 1024
    TEXT_TAGS           = %w(
      COMM COMR ENCR EQUA ETCO GEOB GRID IPLS LINK MCDI MLLT OWNE PRIV PCNT POPM POSS
      RBUF RVAD RVRB SYLT SYTC TALB TBPM TCOM TCON TCOP TDAT TDLY TENC TEXT TFLT TIME
      TIT1 TIT2 TIT3 TKEY TLAN TLEN TMED TOAL TOFN TOLY TOPE TORY TOWN TPE1 TPE2 TPE3
      TPE4 TPOS TPUB TRCK TRDA TRSN TRSO TSIZ TSRC TSSE TYER TXXX UFID USER USLT WCOM
      WCOP WOAF WOAR WOAS WORS WPAY WPUB WXXX APIC
    )
    MIMES = %w(jpg jpeg png)

    def overwrite(tag_hash, output_file_name : String = "")
      raw_mp3 = extract_mp3(@file)
      io = write_all(tag_hash)
      io.write(raw_mp3.to_slice)
      if output_file_name != ""
        File.write("#{output_file_name}.mp3", io.to_slice, perm = PERMS, mode = "wb")
      end
      io
    end

    def write_all(tag_hash)
      tags = read_tags(tag_hash)
      tag_bin = generate_tags(tags)
      header = create_header(tag_bin)
    end

    def create_header(tag_bin)
      size = tag_bin.join.to_s.to_slice.size + NULLBYTE_COUNT
      io = IO::Memory.new
      io.write("ID3".to_slice)
      io.write(Bytes.new(1).map { |b| b = 0x03.to_u8 })
      io.write(Bytes.new(2).map { |b| b = 0x00.to_u8 })
      ba = produce_header_size(size)
      io.write(ba.to_slice)
      io.write(tag_bin.join.to_slice)
      io.write(Bytes.new(NULLBYTE_COUNT).map { |b| b = 0x00.to_u8 })
      io
    end

    def generate_tags(tags)
      tag_bin_array = Array(IO).new
      tags.each do |tag|
        if tag.name != "APIC"
          io = generate_text_tag(tag)
          tag_bin_array << io
        else
          io = generate_image_tag(tag)
          tag_bin_array << io
        end
      end
      tag_bin_array
    end

    def generate_image_tag(tag)
      image = File.read(tag.value)
      io = IO::Memory.new
      mime_type = tag.value.split(".")[-1]
      if !MIMES.includes?(mime_type)
        raise UnsupportedMimeType
      end
      mime_value = "image/#{mime_type}"
      size = image.to_slice.size + mime_value.size + 4
      bits = int_to_bit_array(size, bit_length = 32)
      io.write(tag.name.to_slice)
      io.write(bits.to_slice)
      io.write(Bytes.new(3).map { |b| b = 0x00.to_u8 })
      io.write(mime_value.to_slice)
      io.write(Bytes.new(1).map { |b| b = 0x00.to_u8 })
      io.write(Bytes.new(1).map { |b| b = 0x03.to_u8 })
      io.write(Bytes.new(1).map { |b| b = 0x00.to_u8 })
      io.write(image.to_slice)
      io
    end

    def generate_text_tag(tag)
      string = tag.value.encode("unicode")
      io = IO::Memory.new
      size = string.size + 1
      bits = int_to_bit_array(size, bit_length = 32)
      io.write(tag.name.to_slice)
      io.write(bits.to_slice)
      io.write(Bytes.new(2).map { |b| b = 0x00.to_u8 })
      io.write(Bytes.new(1).map { |b| b = 0x01.to_u8 })
      io.write(string)
      io
    end

    def read_tags(tag_hash)
      tags = Array(Tag).new
      tag_hash.each do |k, v|
        raise InvalidTag unless TEXT_TAGS.includes?(k.to_s)
        tag = Tag.new
        tag.name = k.to_s
        tag.value = v
        tags << tag
      end
      tags
    end
  end
end
