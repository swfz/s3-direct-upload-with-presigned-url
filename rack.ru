# encoding: utf-8

require 'aws-sdk-s3'
require 'securerandom'
require 'awesome_print'

class SimpleServer
  def call(env)
    request = Rack::Request.new(env)
    ap request.params

    extensions = {
      mp4: 'video/mp4',
      jpg: 'image/jpg',
      png: 'image/png'
    }

    case request.path
    when '/'
      [
        200,
        {
          'Content-Type'  => 'text/html',
          'Cache-Control' => 'public, max-age=86400'
        },
        File.open('./index.html', File::RDONLY)
      ]
    when '/presigned_post_url'
      id = SecureRandom.hex
      bucket = Aws::S3::Resource.new.bucket(ENV['AWS_BUCKET'])
      key = "hoge/#{id}.#{request.params['extension']}"
      expires = Time.now
      presigned_object = bucket.presigned_post(
        key: key,
        success_action_status: '201',
        acl: 'public-read',
        content_type: extensions[request.params['extension'].to_sym],
        expires: expires
      )
      body = { url: presigned_object.url, fields: presigned_object.fields }.to_json

      [
        200,
        {
          'Content-Type'  => 'application/json',
        },
        [body]
      ]
    end
  end
end

run SimpleServer.new
