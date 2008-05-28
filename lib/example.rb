require 'healthvault'
require File.dirname(__FILE__) + "/../spec/support/test_server"
include HealthVault

app = Application.default
connection = app.create_connection
connection.authenticate
puts 'authenticated application...'

request = Request.create("GetVocabulary", connection)
request.info.vocabulary_parameters = WCData::Methods::GetVocabulary::VocabularyParameters.new
request.info.vocabulary_parameters.add_vocabulary_key WCData::Vocab::VocabularyKey.new
request.info.vocabulary_parameters.vocabulary_key[0].name = "thing-types"
request.info.vocabulary_parameters.vocabulary_key[0].family = "wc"
request.info.vocabulary_parameters.vocabulary_key[0].version = '1'
request.info.vocabulary_parameters.fixed_culture = 'true'
result = request.send
puts 'got thing-type vocabulary...'

t = TestServer.new
t.open_login
t.wait_for_auth

connection.user_auth_token = t.auth_token
request = Request.create("GetPersonInfo", connection)
result = request.send

record_id = result.info.person_info.selected_record_id

puts result.info.person_info.name
puts 'got person info...'

#request = Request.create("GetThings", connection)
#request.header.record_id = record_id
#request.info.add_group(WCData::Methods::GetThings::ThingRequestGroup.new)
#request.info.group[0].format = WCData::Methods::GetThings::ThingFormatSpec.new
#request.info.group[0].format.add_xml("")
#request.info.group[0].format.add_section("core")
#request.info.group[0].add_filter(WCData::Methods::GetThings::ThingFilterSpec.new)
#request.info.group[0].filter[0].add_type_id("3d34d87e-7fc1-4153-800f-f56592cb0d17")
#
#result = request.send
#puts result.info.group[0].thing[0].data_xml[0].value.kg.to_s
#puts result.xml
