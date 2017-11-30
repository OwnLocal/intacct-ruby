require 'builder'
require 'intacct_ruby/exceptions/unknown_function_type'

module IntacctRuby
  # a function to be sent to Intacct. Defined by a function type (e.g. :create),
  # an object type, (e.g. :customer), and arguments.
  class Function
    ALLOWED_TYPES = %w(
      readByQuery
      readMore
      read
      readByName
      create
      create_invoice
      update
      delete
    ).freeze

    def initialize(function_type, object_type, arguments = {})
      @function_type = function_type.to_s
      @object_type = object_type && object_type.to_s
      @arguments = arguments

      validate_type!
    end

    def delete_read_args(fields, *required_fields)
      return  fields.inject({}) do |args, field|
        value = self.delete_read_args_value(@arguments[field])
        (value && value != "") || required_fields.include?(field) ? args.merge(field=>value) : args
      end
    end

    def delete_read_args_value(value)
      return nil if value.nil? || value == ""
      return value unless value.is_a?(Array)
      return value.join(',')
    end

    def to_xml
      xml = Builder::XmlMarkup.new

      xml.function controlid: controlid do
        if @function_type =~ /^read|delete/
          xml.tag!(@function_type) do
            case @function_type.to_s
            when 'read', 'readByName'
              args = self.delete_read_args([:keys, :fields], :keys)
            when 'readByQuery', 'readMore'
              args = self.delete_read_args([:fields, :query, :pagesize], :query)
            when 'delete'
              args = self.delete_read_args([:keys])
            end
            xml << argument_xml(object: @object_type)
            xml << argument_xml(args)
          end
        else
          xml.tag!(@function_type) do
            if @object_type
              xml.tag!(@object_type.upcase) { xml << argument_xml(@arguments) }
            else
              xml << argument_xml(@arguments)
            end
          end
        end
      end

      xml.target!
    end

  private

    def timestamp
      @timestamp ||= Time.now.utc.to_s
    end

    def controlid
      "#{@function_type}-#{@object_type}-#{timestamp}"
    end

    def argument_xml(arguments_to_convert)
      xml = Builder::XmlMarkup.new

      arguments_to_convert.each do |key, value|
        argument_key = key.to_s.to_sym

        xml.tag!(argument_key) do
          xml << argument_value_as_xml(value)
        end
      end

      xml.target!
    end

    def argument_value_as_xml(value)
      case value
        when Hash
          argument_xml(value) # recursive case
        when Array
          argument_value_list_xml(value) # recursive case
        else
          value.to_s # end case
      end
    end

    def argument_value_list_xml(array_of_hashes)
      xml = Builder::XmlMarkup.new

      array_of_hashes.each do |argument_hash|
        xml << argument_xml(argument_hash)
      end

      xml.target!
    end

    def validate_type!
      unless ALLOWED_TYPES.include?(@function_type)
        raise Exceptions::UnknownFunctionType,
              "Type #{@function_type} not recognized. Function Type must be " \
              "one of #{ALLOWED_TYPES}."
      end
    end
  end
end
