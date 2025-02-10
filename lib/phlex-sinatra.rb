# frozen_string_literal: true

require 'phlex'
require 'phlex/version'
require 'sinatra/base'
require_relative 'phlex/sinatra/version'

module Phlex
  module Sinatra
    Error = Class.new(StandardError)
    ArgumentError = Class.new(Error)
    PHLEX_V2 = !!Phlex::VERSION[/^2\./]
    SINATRA_VIEW_CONTEXT = :__sinatra_view_context__

    class TypeError < Error
      MAX_SIZE = 32

      def initialize(obj)
        content = obj.inspect
        content = content[0, MAX_SIZE] + '…' if content.size > MAX_SIZE
        super "Expected a Phlex instance, received #{content}"
      end
    end

    module V1SGMLOverrides
      def helpers
        @_view_context
      end

      def url(...)
        helpers.url(...)
      end
    end

    module V2SGMLOverrides
      def helpers
        context[SINATRA_VIEW_CONTEXT]
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
          call_with_view_context(obj, self, buffer: out)
        end
      else
        output = call_with_view_context(obj, self)

        if layout
          render(layout_engine, layout, { layout: false }) { output }
        else
          output
        end
      end
    end

    if PHLEX_V2
      def call_with_view_context(obj, view_context, buffer: nil)
        context = { SINATRA_VIEW_CONTEXT => view_context }
        buffer ? obj.call(buffer, context:) : obj.call(context:)
      end
    else
      def call_with_view_context(obj, view_context, buffer: nil)
        buffer ? obj.call(buffer, view_context:) : obj.call(view_context:)
      end
    end
  end

  if Phlex::Sinatra::PHLEX_V2
    SGML.include Sinatra::V2SGMLOverrides
  else
    SGML.include Sinatra::V1SGMLOverrides
  end
end

Sinatra.helpers Phlex::Sinatra
