require File.dirname(__FILE__) + "/support/test_server"
require File.dirname(__FILE__) + "/../lib/connection"
include HealthVault

describe Connection do
  before(:each) do
    @connection = Connection.new
  end

  it "application should be authenticated" do
    @connection.authenticated?.should == true
  end
  
  it "should authenticate a user" do
    @test_server = TestServer.new
    @test_server.open_login
    @test_server.wait_for_auth
    @connection.credential.user_auth_token = @test_server.auth_token
    @connection.authenticated?(:user).should == true
  end
end

