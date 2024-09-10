# phlex-sinatra

[Phlex](https://github.com/phlex-ruby/phlex) already works with Sinatra (and everything else) but its normal usage leaves you without access to Sinatra's standard helper methods. This integration lets you use the `url()` helper method from within a Phlex view (along with the rest of the helper methods available in a Sinatra action).

## Installation

Add phlex-sinatra to your application's Gemfile and run `bundle install`.

```ruby
gem 'phlex-sinatra'
```

## Usage

To enable the integration use the `phlex` method in your Sinatra action and pass an _instance_ of the Phlex view (instead of using `.call` to get its output):

```ruby
get '/foo' do
  phlex MyView.new
end
```

You can now use Sinatra's `url()` helper method directly and its other methods (`params`, `request`, etc) via the `helpers` proxy:

```ruby
class MyView < Phlex::HTML
  def view_template
    h1 { 'Phlex / Sinatra integration' }
    p {
      a(href: url('/foo', false)) { 'link to foo' }
    }
    pre { helpers.params.inspect }
  end
end
```

You can also pass an alternative content type – which defaults to `:html` (or `:svg` for a `Phlex::SVG` instance):

```ruby
get '/foo' do
  phlex MyView.new, content_type: :xml
end
```

## Layout

If your entire view layer uses Phlex then layout will be a part of your component structure but maybe you've got an existing non-Phlex layout or you don't want to use Phlex for _everything_, in which case standard Sinatra layouts are supported.

Pass `layout: true` to wrap the Phlex output with Sinatra's default layout -- a file named "layout.erb" in the configured views directory (ERB is the default) -- or pass a symbol to specify the file:

```ruby
get '/foo' do
  # This Phlex view will be wrapped by `views/my_layout.erb`.
  phlex MyView.new, layout: :my_layout
end
```

Other [Sinatra templating languages](https://sinatrarb.com/intro.html#available-template-languages) can be specified via the `layout_engine` keyword:

```ruby
get '/foo' do
  # This Phlex view will be wrapped by `views/layout.haml`.
  phlex MyView.new, layout: true, layout_engine: :haml
end
```

## Using Phlex in other templates

It's also possible to call `phlex` from within other views, for instance an ERB template:

```erb
<%= phlex MyView.new %>
```

A `layout` can also be passed:

```erb
<%= phlex MyView.new, layout: :wrapper %>
```

## Streaming

Streaming a Phlex view can be enabled by passing `stream: true` which will cause Phlex to automatically write to the response after the closing `</head>` and buffer the remaining content:

```ruby
get '/foo' do
  phlex MyView.new, stream: true
end
```

Even with no further intervention this small change means that the browser will receive the complete `<head>` as quickly as possible and can start fetching and processing its external resources while waiting for the rest of the page to download.

You can also manually flush the contents of the buffer at any point using Phlex's `#flush` method:

```ruby
class Layout < Phlex::HTML
  def view_template(&block)
    doctype
    html {
      head {
        # All the usual stuff: links to external stylesheets and JavaScript etc.
      }
      # Phlex will automatically flush to the response at this point which will
      # benefit all pages that opt in to streaming.
      body {
        # Standard site header and navigation.
        render Header.new

        yield_content(&block)
      }
    }
  end
end

class MyView < Phlex::HTML
  def view_template
    render Layout.new {
      # Knowing that this page can take a while to generate we can choose to
      # flush here so the browser can render the site header while downloading
      # the rest of the page - which should help minimise the First Contentful
      # Paint metric.
      flush

      # The rest of the big long page...
    }
  end
end
```

## Why do I need Sinatra's `url()` helper?

It might not seem obvious at first why you'd use `url()` at all given that you mostly just pass the string you want to output and then probably `false` so the scheme/host isn't included.

There are a couple of reasons:

1. **Linking to a full URL**

   Sometimes you need to link to a page on the site using its full URL – for instance within a feed or for an `og:image` social media preview image link.

2. **Awareness that the app is being served from a subdirectory**

   This isn't something you encounter very often in a standard Sinatra app but you hit it quite quickly if you're using [Parklife](https://github.com/benpickles/parklife) to generate a static build hosted on GitHub Pages – which is exactly what prompted me to write this integration.

   In this case by using the `url()` helper you won’t have to change anything when switching between serving the app from `/` in development and hosting it at `/my-repository/` in production – internal links to other pages/stylesheets/etc will always be correct regardless.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/benpickles/phlex-sinatra>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/benpickles/phlex-sinatra/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the phlex-sinatra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/benpickles/phlex-sinatra/blob/main/CODE_OF_CONDUCT.md).
