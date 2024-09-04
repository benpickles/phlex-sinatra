# frozen_string_literal: true

require 'phlex'
require_relative 'phlex/sinatra/version'

module Phlex
  module Sinatra
    Error = Class.new(StandardError)
    IncompatibleOptionError = Class.new(Error)

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
    def phlex(obj, content_type: nil, layout: false, stream: false)
      raise Phlex::Sinatra::TypeError.new(obj) unless obj.is_a?(Phlex::SGML)

      content_type ||= :svg if obj.is_a?(Phlex::SVG) && !layout
      self.content_type(content_type) if content_type

      # Copy Sinatra's behaviour and interpret layout=true as meaning "use the
      # default layout" - uses an internal Sinatra instance variable :s
      layout = @default_layout if layout == true

      if stream
        raise Phlex::Sinatra::IncompatibleOptionError.new(
          'streaming is not compatible with layout'
        ) if layout

        self.stream do |out|
          obj.call(out, view_context: self)
        end
      else
        output = obj.call(view_context: self)

        if layout
          render(:erb, layout, { layout: false }) { output }
        else
          output
        end
      end
    end
  end
end
