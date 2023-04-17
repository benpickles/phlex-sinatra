# frozen_string_literal: true

require 'phlex'
require_relative 'phlex/sinatra/version'

module Phlex
  module Sinatra
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
    def phlex(obj)
      obj.call(view_context: self)
    end
  end
end
