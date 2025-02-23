## Version 0.5.0 - 2025-02-23

- Add support for Phlex 2, drop support for Phlex 1 - this also means the minimum required Ruby version is now 3.2.
- Reimplement this library to use the official Sinatra extension API. For a modular-style app the extension must now be explicitly registered:

  ```ruby
  class MyApp < Sinatra::Base
    helpers Phlex::Sinatra
  end
  ```

## Version 0.4.0 - 2024-09-10

- Add support for wrapping a Phlex view in a layout. Pass `layout: true` to use Sinatra's default layout or specify the view by passing a symbol. Defaults to ERB and other Sinatra templating languages can be specified via the `layout_engine:` keyword.

## Version 0.3.0 - 2023-12-13

- Add support for streaming a view. Pass `stream: true` to the `#phlex` helper so Phlex will use Sinatra's streaming capability.

## Version 0.2.0 - 2023-04-24

- Allow passing a `content_type:` kwarg to the `#phlex` helper so it behaves like Sinatra's other template helpers (defaults to `:html` – or `:svg` for a `Phlex::SVG` instance).
- Raise an informative error message if the `#phlex` helper receives something other than a Phlex instance.

## Version 0.1.0 - 2023-04-17

- Initial release
