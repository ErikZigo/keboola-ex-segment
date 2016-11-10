require 'aws-sdk'
require 'zlib'
require 'csv'
require 'optparse'

class Segment

    def initialize(options)

        @config = JSON.parse(File.read(options[:data] + '/config.json'))
        @out_bucket = @config["parameters"]["outputbucket"]
        @s3_bucket = @config["parameters"]["s3_bucket"]
        @s3_prefix = @config["parameters"]["s3_prefix"]
        @access_key = @config["parameters"]["#access_key"]
        @secret_access_key = @config["parameters"]["#secret_access_key"]
        @region = @config["parameters"]["region"]

        @in_file = options[:data] + '/in/tables/file.gz'
        @in_file_decompressed = options[:data] + '/in/tables/file.csv'
        @out_file = options[:data] + '/out/tables/out.csv'

        @kbc_api_token = ENV["KBC_TOKEN"]

    end

    def download()

      s3 = Aws::S3::Resource.new(
        access_key_id: @access_key,
        secret_access_key: @secret_access_key,
        region: @region
      )

      client = Aws::S3::Client.new(
        access_key_id: @access_key,
        secret_access_key: @secret_access_key,
        region: @region
      )

      data_files = s3.bucket(@s3_bucket).objects(prefix: @s3_prefix, delimiter: '').collect(&:key)

      data_files.each { |key|

      puts key
      reap = client.get_object({ bucket: @s3_bucket, key: key }, target: @in_file)

      Zlib::GzipReader.open(@in_file) do | input_stream |
        File.open(@in_file_decompressed, "a", :quote_char => '|') do |output_stream|
          IO.copy_stream(input_stream, output_stream)
        end
      end

      }

      CSV.open(@out_file, "ab", :col_sep => '|') do |header|
          header << ["data"]
      end

      CSV.foreach(@in_file_decompressed, :encoding => 'utf-8', :quote_char => '`', :col_sep => '|') do |row|

        CSV.open(@out_file, "ab") do |rows|
            rows << row
        end

      end

      return true

    end

end