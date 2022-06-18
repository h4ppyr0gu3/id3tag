require "bit_array"
require "io"
require "uuid"

module Id3tag
  class Base
    PERMS = File::Permissions.new(0o600)

    def initialize(file : File)
      @file = file
      @tags = Array(Tag).new
    end

    def read_length
      array = header_bit_arrays(@file)
      binary_size = process_array(array)
      binary_to_int(binary_size)
    end

    def produce_header_size(size)
      ba = int_to_bit_array_header(size, bit_length = 32)
      cba = BitArray.new(32)
      i = [1, 2, 3, 4].reverse!
      i.each do |int|
        temp = ba[((8 * (int - 1)))..((8 * int) - 1)]
        temp.reverse!
        (((8 * (int - 1)))..((8 * int) - 1)).each_with_index do |cor, idx|
          if temp[idx] && idx != 0
            cba.toggle(cor)
          end
        end
        ba.rotate!
      end
      cba
    end

    def header_size(input_file)
      header_size_array = header_bit_arrays(input_file)
      header_array_compact = process_array(header_size_array)
      header_size = binary_to_int(header_array_compact)
      header_size
    end

    def extract_mp3(file)
      header_size = header_size(file)
      file.pos = header_size + 10
      file.gets_to_end
    end

    def extract_header(temp_file : String, input_file : File)
      header_size = header_size(input_file)
      input_file.read_at(0, header_size + 10) do |byte|
        File.write(temp_file, byte, mode: "wb")
      end
      temp_file
    end

    #  methods beyond this point

    def header_bit_arrays(file)
      array = Array(BitArray).new
      file.read_at(6, 4) do |header|
        header.each_byte do |test|
          array << int_to_bit_array(test)
        end
      end
      array
    end

    def int_to_bit_array_header(val : Int, bit_length = 32)
      ba = BitArray.new(bit_length)
      value = val
      (1..bit_length).each do |x|
        if (value % 2) == 1.0
          ba[x - 1] = true
        end
        value = (value / 2).to_i
      end
      if bit_length > 8 && (bit_length % 8) == 0
        return handle_greater_than_8_header(ba)
      end
      ba
    end

    def handle_greater_than_8_header(ba)
      len = ba.size / 8
      cba = BitArray.new(ba.size)
      (1..(len.to_i)).each do |int|
        ban = ba[((int * 8) - 8)..((int * 8) - 1)]
        ban.reverse!.map_with_index do |val, idx|
          if val && idx != 0
            cba.toggle((((4 - int) * 8) + idx))
          end
        end
      end
      cba
    end

    def int_to_bit_array(val : Int, bit_length = 8)
      ba = BitArray.new(bit_length)
      value = val
      (1..bit_length).each do |x|
        if (value % 2) == 1.0
          ba[x - 1] = true
        end
        value = (value / 2).to_i
      end

      if bit_length > 8 && (bit_length % 8) == 0
        return handle_greater_than_8(ba)
      end
      ba.reverse!
    end

    def handle_greater_than_8(ba)
      len = ba.size / 8
      cba = BitArray.new(ba.size)
      (1..(len.to_i)).each do |int|
        ban = ba[((int * 8) - 8)..((int * 8) - 1)]
        ban.map_with_index do |val, idx|
          if val
            cba.toggle((((4 - int) * 8) + idx))
          end
        end
      end
      cba
    end

    def process_array(array)
      new_array = Array(BitArray).new
      array.map do |ba|
        val = BitArray.new(7)
        ba.reverse!.each_with_index do |x, idx|
          idx != 7 && x ? (val[idx] = true) : next
        end
        new_array << val
      end
      join_bit_array(new_array.reverse, 32)
    end

    def join_bit_array(array : Array(BitArray), length : Int)
      val = BitArray.new(length)
      count = 0
      array.each do |ba|
        ba.each do |bit|
          if bit
            val[count] = true
          end
          count += 1
        end
      end
      val
    end

    def binary_to_int(binary : BitArray)
      value = 0
      binary.each_with_index do |bool, idx|
        if bool
          value = value + 2**idx
        end
      end
      value
    end
  end
end
