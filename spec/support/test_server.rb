require 'cgi'
require 'webrick'
require 'thread'

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
  
  def open_login
    system("open","https://account.healthvault-ppe.com/redirect.aspx?target=AUTH&targetqs=?appid=05a059c9-c309-46af-9b86-b06d42510550%26redirect=http://localhost:7331/testAuth")
  end
  
end