# frozen_string_literal: true

require 'phlex'
require_relative 'phlex/sinatra/version'

module Phlex
  module Sinatra
    Error = Class.new(StandardError)

    class TypeError < Error
      MAX_SIZE = 32

      def initialize(obj)
        content = obj.inspect
        content = content[0, MAX_SIZE] + '…' if content.size > MAX_SIZE
        super "Expected a Phlex instance, received #{content}"
      end
    end

    module SGML
      module Overrides
        def helpers
          @_view_context
        end

        def url(...)
          helpers.url(...)
        end
      end
    end
  end

  class SGML
    include Sinatra::SGML::Overrides
  end
end

module Sinatra
  module Templates
    def phlex(obj, content_type: nil, stream: false)
      raise Phlex::Sinatra::TypeError.new(obj) unless obj.is_a?(Phlex::SGML)

      content_type ||= :svg if obj.is_a?(Phlex::SVG)
      self.content_type(content_type) if content_type

      if stream
        self.stream do |out|
          obj.call(out, view_context: self)
        end
      else
        obj.call(view_context: self)
      end
    end
  end
end
