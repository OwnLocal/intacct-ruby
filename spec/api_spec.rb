require 'spec_helper'
require 'intacct_ruby/api'

describe IntacctRuby::Api do
  describe :send_request do

    it 'sends a request via HTTPS' do
      request_xml = '<xml>some xml</xml>'

      request = class_double('Request')
      expect(request).to receive(:to_xml).and_return(request_xml)

      post_request_spy = instance_double('Net::HTTP::Post')
      expect(post_request_spy).to receive(:body=).and_return(request_xml)
      expect(post_request_spy).to receive(:[]=).and_return({
        'Content-Type' => 'x-intacct-xml-request'
      })

      http_gateway_spy = instance_double('Net::HTTP')
      expect(http_gateway_spy).to receive(:use_ssl=).and_return(true)
      expect(http_gateway_spy).to receive(:request).and_return(post_request_spy)

      IntacctRuby::Api.new(http_gateway_spy).send_request(request, post_request_spy)

    end
  end
end
