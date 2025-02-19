# frozen_string_literal: true

require 'phlex'
require 'sinatra/base'
require_relative 'phlex/sinatra/version'

module Phlex
  module Sinatra
    Error = Class.new(StandardError)
    ArgumentError = Class.new(Error)

    class TypeError < Error
      MAX_SIZE = 32

      def initialize(obj)
        content = obj.inspect
        content = content[0, MAX_SIZE] + '…' if content.size > MAX_SIZE
        super "Expected a Phlex instance, received #{content}"
      end
    end

    module SGMLOverrides
      def helpers
        @_view_context
      end

      def url(...)
        helpers.url(...)
      end
    end

    def phlex(
      obj,
      content_type: nil,
      layout: false,
      layout_engine: :erb,
      stream: false
    )
      raise TypeError.new(obj) unless obj.is_a?(SGML)

      if layout && stream
        raise ArgumentError.new('streaming is not compatible with layout')
      end

      content_type ||= :svg if obj.is_a?(SVG) && !layout
      self.content_type(content_type) if content_type

      # Copy Sinatra's behaviour and interpret layout=true as meaning "use the
      # default layout" - uses an internal Sinatra instance variable :s
      layout = @default_layout if layout == true

      if stream
        self.stream do |out|
          obj.call(out, view_context: self)
        end
      else
        output = obj.call(view_context: self)

        if layout
          render(layout_engine, layout, { layout: false }) { output }
        else
          output
        end
      end
    end
  end

  SGML.include Sinatra::SGMLOverrides
end

Sinatra.helpers Phlex::Sinatra
