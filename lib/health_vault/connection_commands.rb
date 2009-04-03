module HealthVault
  module ConnectionCommands
    
    def create_request(method_name)
      req = HealthVault::Request.create(method_name, self)      
      yield(req) if block_given?
      req
    end
    
    def send_request(method_name, &block)
      create_request(method_name, &block).send
    end
    
    def user_record_id
      unless @user_record_id
        return unless user_auth_token
        result = send_request("GetPersonInfo")
        @user_record_id = result.info.person_info.selected_record_id
      end
      @user_record_id
    end
    
    def put_thing(thing)
      send_request("PutThings") do |r|
        r.header.record_id = user_record_id
        r.info.thing << thing
      end
    end
    
  end
end