require 'cgi'
require 'webrick'
require 'thread'
require File.dirname(__FILE__) + '/../../lib/config'

class TestServer  
  include WEBrick
  attr_reader :auth_token
  def initialize
    @http_server = HTTPServer.new(:Port => 7331)
    @auth_token = ""
    @done = false
    @http_server.mount_proc("/testAuth") do |req, res|
      @auth_token = CGI::unescape(req.request_line.match(/wctoken=(.*3d)[\&\s]/)[1])
      res.body = "got auth_token: #{@auth_token}"
      res.body << "\n\n\nContinuing on...\nOk to close window"
      res['Content-Type'] = 'text/plain'
      @done = true
    end
    @server_thread = Thread.new { @http_server.start }  
  end
  
  def wait_for_auth
    while(!@done)
      sleep(1)
    end
    @http_server.shutdown
  end
  
  def open_login # TODO: Figure out how to do this in JRuby
    config = Configuration.instance
    auth_url = "#{config.shell_url}/redirect.aspx?target=AUTH&targetqs=?appid=#{config.app_id}%26redirect=http://localhost:7331/testAuth"

    if RUBY_PLATFORM =~ /(:?mswin|mingw)/ # Windows
      system("start #{auth_url}")
    elsif RUBY_PLATFORM =~ /darwin/ # Mac (Darwin, really)
      system("open", auth_url)
    else
      # TODO: Launch the default browser on other platforms.
      system("firefox", auth_url)
    end
  end

end