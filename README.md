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
  def template
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

## Why?

It might not seem obvious at first why you'd use `url()` at all given that you mostly just pass the string you want to output and then probably `false` so the scheme/host isn't included.

There are a couple of reasons:

1. **Linking to a full URL**

   Sometimes you need to link to a page on the site using its full URL – for instance within a feed or for an `og:image` social media preview image link.

2. **Awareness that the app is being served from a subdirectory**

   This isn't something you encounter very often in a standard Sinatra app but you hit it quite quickly if you're using [Parklife](https://github.com/benpickles/parklife) to generate a static build which you host on GitHub Pages – which is exactly what prompted me to write this integration.

   In this case by using the `url()` helper you won’t have to change anything when switching between serving the app from `/` in development and hosting it at `/my-repository/` in production – internal links to other pages/stylesheets/etc will always be correct regardless.

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/benpickles/phlex-sinatra>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/benpickles/phlex-sinatra/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the phlex-sinatra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/benpickles/phlex-sinatra/blob/main/CODE_OF_CONDUCT.md).
