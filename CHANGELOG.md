## Version 0.3.0 - 2023-12-13

- Add support for streaming a view. Pass `stream: true` to the `#phlex` helper so Phlex will use Sinatra's streaming capability.

## Version 0.2.0 - 2023-04-24

- Allow passing a `content_type:` kwarg to the `#phlex` helper so it behaves like Sinatra's other template helpers (defaults to `:html` – or `:svg` for a `Phlex::SVG` instance).
- Raise an informative error message if the `#phlex` helper receives something other than a Phlex instance.

## Version 0.1.0 - 2023-04-17

- Initial release
