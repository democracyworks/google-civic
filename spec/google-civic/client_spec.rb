require 'helper'

describe GoogleCivic::Client do
  it 'should work with an api key' do
    stub_get("https://www.googleapis.com/civicinfo/v2/elections?key=abc123").
      with(:headers => {'Accept'=>'*/*'}).
      to_return(:status => 200, :body => '', :headers => {})
    proc {
      GoogleCivic::Client.new(:key=> "abc123")
    }.should_not raise_exception
  end

  before do
    @client = GoogleCivic::Client.new(:key => "abc123")
  end

  describe "#elections" do
    it "should list the elections in the API" do
      stub_get("/elections?key=abc123").
        to_return(:status => 200, :body => fixture("elections.json"), :headers => {})
      elections = @client.elections
      elections.first.should eql ["kind", "civicinfo#electionsqueryresponse"]
    end
  end

  describe "#voter_info" do
    it "should return the voter information from an address" do
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return(:status => 200, :body => fixture("voter_info.json"), :headers => {})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS")
      voter_info.election.name.should eql "VIP Test Election"
    end

    it "should take a query parameter" do
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&includeOffices=true&key=abc123").
       to_return(:status => 200, :body => fixture("voter_info.json"), :headers => {})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS", {includeOffices: true})
      voter_info.election.name.should eql "VIP Test Election"
    end

    it "should retry on server error when connection_options includes retry config" do
      retry_config = {max: 10, interval: 2}
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return({:status => 500, :body => fixture("server_error.json")},
                 {:status => 200, :body => fixture("voter_info.json")})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS", {connection: {retry: retry_config}})
      voter_info.election.name.should eql "VIP Test Election"
    end

    it "should retry on retriable error when connection_options includes retry config" do
      retry_config = {max: 10, interval: 2}
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return({:status => 403, :body => fixture("retriable_error.json")},
                 {:status => 200, :body => fixture("voter_info.json")})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS", {connection: {retry: retry_config}})
      voter_info.election.name.should eql "VIP Test Election"
    end

    it "should not retry more than the count" do
      retry_config = {max: 2, interval: 1}
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return({:status => 500, :body => fixture("server_error.json")},
                 {:status => 500, :body => fixture("server_error.json")},
                 {:status => 500, :body => fixture("server_error.json")})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS", {connection: {retry: retry_config}})
      voter_info.error.code.should eql 500
    end

    it "should not retry on a non-retriable error" do
      retry_config = {max: 2, interval: 1}
      stub_get("/voterinfo?electionId=2000&address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return({:status => 403, :body => fixture("non_retriable_error.json")})
      voter_info = @client.voter_info(2000, "1263 Pacific Ave. Kansas City KS", {connection: {retry: retry_config}})
      voter_info.error.code.should eql 403
    end

  end

  describe "#representative_info" do
    it "should return the representative information from an address" do
     stub_get("/representatives?address=1263+Pacific+Ave.+Kansas+City+KS&key=abc123").
       to_return(:status => 200, :body => fixture("representative.json"), :headers => {})
      rep_info = @client.representative_info("1263 Pacific Ave. Kansas City KS")
      rep_info.offices.first[1].name.should eql "United States House of Representatives KS-03"
    end
  end

end
