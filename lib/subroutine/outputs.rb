# frozen_string_literal: true

require "active_support/concern"
require "subroutine/outputs/configuration"
require "subroutine/outputs/output_not_set_error"
require "subroutine/outputs/unknown_output_error"

module Subroutine
  module Outputs

    extend ActiveSupport::Concern

    included do
      class_attribute :output_configurations
      self.output_configurations = {}

      attr_reader :outputs
    end

    module ClassMethods

      def outputs(*names)
        options = names.extract_options!
        names.each do |name|
          config = ::Subroutine::Outputs::Configuration.new(name, options)
          self.output_configurations = output_configurations.merge(name.to_sym => config)

          class_eval <<-EV, __FILE__, __LINE__ + 1
            def #{name}
              get_output(:#{name})
            end
          EV
        end
      end

    end

    def setup_outputs
      @outputs = {}.with_indifferent_access
    end

    def output(name, value)
      unless output_configurations.key?(name.to_sym)
        raise ::Subroutine::Outputs::UnknownOutputError, name
      end

      outputs[name.to_sym] = value
    end

    def get_output(name)
      name = name.to_sym
      raise ::Subroutine::Outputs::UnknownOutputError, name unless output_configurations.key?(name)

      outputs[name]
    end

    def validate_outputs!
      output_configurations.each_pair do |name, config|
        if config.required? && !outputs.key?(name)
          raise ::Subroutine::Outputs::OutputNotSetError, name
        end
      end
    end

  end
end