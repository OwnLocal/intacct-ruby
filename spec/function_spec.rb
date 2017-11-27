require 'spec_helper'
require 'nokogiri'

require 'intacct_ruby/function'
require 'intacct_ruby/exceptions/unknown_function_type'

include IntacctRuby

def to_xml_key(symbol)
  symbol.to_s
end

describe Function do
  describe :initialize do
    context 'given a valid function type' do
      it 'creates a function without error' do
        type = Function::ALLOWED_TYPES.first

        expect {
          Function.new(type, :objecttype, some: 'argument')
        }.not_to raise_error
      end
    end

    context 'given an invalid function type' do
      it 'raises an error' do
        expect {
          Function.new(:badtype, :objecttype, some: 'argument')
        }.to raise_error(Exceptions::UnknownFunctionType)
      end
    end
  end

  describe :delete_read_args_value do
    subject { Function.new(:create, :widget, {}) }

    it 'converts a an array to comma-separated list' do
      expect(subject.delete_read_args_value(%w{one two three})).to eq('one,two,three')
    end

    it 'returns the value passed if not an array' do
      expect(subject.delete_read_args_value('four')).to eq('four')
    end

    it 'returns nil if the value passed is an empty string' do
      expect(subject.delete_read_args_value('')).to be_nil
    end

    it 'returns nil if the value passed is nil' do
      expect(subject.delete_read_args_value(nil)).to be_nil
    end
  end

  describe 'delete_read_args' do
    let(:object_type) { :objecttype }
    let(:function_type) { :readByQuery }
    let(:fields) { 'fields' }
    let(:query) { 'field=value' }
    let(:keys) { 'some-keys-value' }
    let(:arguments) do
      {
        fields: fields,
        query: query,
        keys: keys
      }
    end
    let(:function) { Function.new(function_type, object_type, arguments) }

    it 'calls delete_read_args_value with each supplied key and includes it' do
      expect(function).to receive(:delete_read_args_value).with(fields).and_return(fields)
      function.delete_read_args([:fields])[:fields] == fields
    end

    it "calls delete_read_args_value with each supplied key but excludes it if it's blank" do
      expect(function).to receive(:delete_read_args_value).with(fields).and_return(nil)
      expect(function.delete_read_args([:fields]).keys).not_to include(:fields)

      expect(function).to receive(:delete_read_args_value).with(fields).and_return('')
      expect(function.delete_read_args([:fields]).keys).not_to include(:fields)
    end

    it "calls delete_read_args_value with each supplied key and includes it
        if it's blank in the subsequent required array" do
      expect(function).to receive(:delete_read_args_value).with(fields).and_return(nil)
      expect(function.delete_read_args([:fields], :fields).keys).to include(:fields)

      expect(function).to receive(:delete_read_args_value).with(fields).and_return('')
      expect(function.delete_read_args([:fields], :fields).keys).to include(:fields)
    end
  end

  describe :to_xml do
    let(:object_type) { :objecttype }
    let(:function) { Function.new(function_type, object_type, arguments) }
    let(:xml) { Nokogiri::XML function.to_xml }

    describe 'delete' do
      let(:function_type) { :delete }
      let(:fields) { ['field1', 'field2', 'fieldThree'] }
      let(:query) { 'field=value' }
      let(:arguments) do
        {
          query: 'widget=value',
          query: fields
        }
      end

      it 'has a controlid' do
        xml_controlid = xml.xpath('function').first.attributes['controlid'].value

        expect(xml_controlid).to include(function_type.to_s, object_type.to_s)
      end

      it 'calls delete_read_args has an object node with no params' do
        expect(function).to receive(:delete_read_args).with([:keys])
          .and_return({ widget: 'value' })
        expect(function).to receive(:argument_xml).with({ object: object_type.to_s })
          .and_return("<object>#{object_type}</object>")
        expect(function).to receive(:argument_xml).with({ widget: 'value' })
          .and_return('<widget>value</widget>')

        expect(xml.xpath("//#{function_type}").children[0].name).to eq('object')
        expect(xml.xpath("//#{function_type}/object").inner_text).to eq(object_type.to_s)
        expect(xml.xpath("//#{function_type}/widget").inner_text).to eq('value')
      end
    end

    describe 'read style' do
      let(:fields) { ['field1', 'field2', 'fieldThree'] }
      let(:query) { 'field=value' }
      let(:arguments) do
        {
          query: 'widget=value',
          fields: fields
        }
      end

      describe 'readByQuery' do
        let(:function_type) { :readByQuery }

        it 'has a controlid' do
          xml_controlid = xml.xpath('function').first.attributes['controlid'].value

          expect(xml_controlid).to include(function_type.to_s, object_type.to_s)
        end

        it 'calls delete_read_args has an object node with no params' do
          expect(function).to receive(:delete_read_args).with([:fields, :query, :pagesize], :query)
            .and_return({ widget: 'value' })
          expect(function).to receive(:argument_xml).with({ object: object_type.to_s })
            .and_return("<object>#{object_type}</object>")
          expect(function).to receive(:argument_xml).with({ widget: 'value' })
            .and_return('<widget>value</widget>')

          expect(xml.xpath("//#{function_type}").children[0].name).to eq('object')
          expect(xml.xpath("//#{function_type}/object").inner_text).to eq(object_type.to_s)
          expect(xml.xpath("//#{function_type}/widget").inner_text).to eq('value')
        end
      end

      describe 'readMore' do
        let(:function_type) { :readMore }

        it 'has a controlid' do
          xml_controlid = xml.xpath('function').first.attributes['controlid'].value

          expect(xml_controlid).to include(function_type.to_s, object_type.to_s)
        end

        it 'calls delete_read_args has an object node with no params' do
          expect(function).to receive(:delete_read_args).with([:fields, :query, :pagesize], :query)
            .and_return({ widget: 'value' })
          expect(function).to receive(:argument_xml).with({ object: object_type.to_s })
            .and_return("<object>#{object_type}</object>")
          expect(function).to receive(:argument_xml).with({ widget: 'value' })
            .and_return('<widget>value</widget>')

          expect(xml.xpath("//#{function_type}").children[0].name).to eq('object')
          expect(xml.xpath("//#{function_type}/object").inner_text).to eq(object_type.to_s)
          expect(xml.xpath("//#{function_type}/widget").inner_text).to eq('value')
        end
      end

      describe 'read' do
        let(:function_type) { :read }

        it 'has a controlid' do
          xml_controlid = xml.xpath('function').first.attributes['controlid'].value

          expect(xml_controlid).to include(function_type.to_s, object_type.to_s)
        end

        it 'calls read_args has an object node with no params' do
          expect(function).to receive(:delete_read_args).with([:keys, :fields], :keys)
            .and_return({ widget: 'value' })
          expect(function).to receive(:argument_xml).with({ object: object_type.to_s })
            .and_return("<object>#{object_type}</object>")
          expect(function).to receive(:argument_xml).with({ widget: 'value' })
            .and_return('<widget>value</widget>')

          expect(xml.xpath("//#{function_type}").children[0].name).to eq('object')
          expect(xml.xpath("//#{function_type}/object").inner_text).to eq(object_type.to_s)
          expect(xml.xpath("//#{function_type}/widget").inner_text).to eq('value')
        end
      end

      describe 'readByName' do
        let(:function_type) { :readByName }

        it 'has a controlid' do
          xml_controlid = xml.xpath('function').first.attributes['controlid'].value

          expect(xml_controlid)
            .to include function_type.to_s, object_type.to_s
        end

        it 'calls read_args has an object node with no params' do
          expect(function).to receive(:delete_read_args).with([:keys, :fields], :keys)
            .and_return({ widget: 'value' })
          expect(function).to receive(:argument_xml).with({ object: object_type.to_s })
            .and_return("<object>#{object_type}</object>")
          expect(function).to receive(:argument_xml).with({ widget: 'value' })
            .and_return('<widget>value</widget>')

          expect(xml.xpath("//#{function_type}").children[0].name).to eq('object')
          expect(xml.xpath("//#{function_type}/object").inner_text).to eq(object_type.to_s)
          expect(xml.xpath("//#{function_type}/widget").inner_text).to eq('value')
        end
      end

    end

    describe 'create' do
      let(:function_type) { :create }
      let(:arguments) do
        {
          some: 'argument',
          another: 'string',
          nested_as_hash: { nested_key: 'nested value' },
          another_nested_as_hash: { another_key: 'another value' },
          nested_as_array: [
            { first_key:  'first_value'  },
            { second_key: 'second_value' }
          ]
        }
      end

      it 'has a controlid' do
        xml_controlid = xml.xpath('function').first.attributes['controlid'].value

        expect(xml_controlid).to include(function_type.to_s, object_type.to_s)
      end

      it 'has a function type' do
        expect(xml.xpath('function').children.first.name).to eq(function_type.to_s)
      end

      it 'has an object type with proper formatting' do
        expect(xml.xpath("//#{function_type}").children.first.name).to eq object_type.to_s.upcase
      end

      context 'given non-nested arguments' do
        it 'has function arguments as key/value pairs' do
          arguments.select {
            |_, value| [String, Integer].include?(value.class)
          }.each do |key, expected_value|
            xml_object_key = object_type.upcase
            xml_argument_key = to_xml_key key

            xml_argument_value = xml.xpath("//#{xml_object_key}/#{xml_argument_key}")

            expect(xml_argument_value.first.children.to_s).to eq(expected_value)
          end
        end
      end

      context 'given nested arguments' do
        context 'given that nested arguments are in hash' do
          it 'converts those arguments to nested XML' do
            arguments.select { |_, value| value.is_a? Hash }.each do |key, nested_value|
              xml_object_key = object_type.upcase
              xml_outer_key = to_xml_key key

              nested_value.each do |inner_key, inner_value|
                xml_inner_key = to_xml_key inner_key
                xml_inner_value = xml.xpath("//#{xml_object_key}/#{xml_outer_key}/#{xml_inner_key}")

                expect(xml_inner_value.first.children.to_s).to eq(inner_value)
              end
            end
          end
        end

        context 'given that those arguments are in an array' do
          it 'converts those arguments to an XML list' do
            arguments.select { |_, value| value.is_a? Array }.each do |outer_key, array_body|
              xml_object_key = object_type.upcase
              xml_array_key = to_xml_key outer_key # key of XML Array

              array_body.each do |hash_entry| # because array of hashes
                hash_entry.each do |array_item_key, array_item_value|
                  xml_array_item_key = to_xml_key array_item_key
                  xml_array_item_value = xml.xpath(
                    "//#{xml_object_key}/#{xml_array_key}/#{xml_array_item_key}"
                  )

                  expect(xml_array_item_value.first.children.to_s).to eq(array_item_value)
                end
              end
            end
          end
        end
      end
    end

  end
end
