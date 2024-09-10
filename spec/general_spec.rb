# frozen_string_literal: true

class FooView < Phlex::HTML
  def initialize(text = 'foo')
    @text = text
  end

  def view_template
    p { @text }
  end
end

class LinkView < Phlex::HTML
  def initialize(full = false)
    @full = full
  end

  def view_template
    a(href: url('/bar', @full)) { 'link' }
  end
end

class MoreDetailsView < Phlex::HTML
  def view_template
    pre { helpers.params.inspect }
  end
end

class SvgElem < Phlex::SVG
  def view_template
    svg { rect(width: 100, height: 100) }
  end
end

class TestApp < Sinatra::Application
  set :environment, :test

  get '/error' do
    obj = case params[:type]
    when 'phlex-class'
      FooView
    when 'string'
      FooView.call
    when 'string-long'
      FooView.call(('a'..'z').to_a.join(' '))
    end

    phlex obj
  end

  get '/foo' do
    FooView.call
  end

  get '/inline' do
    erb :inline
  end

  get '/inline_with_layout' do
    erb :inline_with_layout
  end

  get '/link' do
    phlex LinkView.new(params[:full])
  end

  get '/more' do
    phlex MoreDetailsView.new
  end

  get '/more-with-layout' do
    layout = params[:layout] == 'true' ? true : :layout_more
    phlex MoreDetailsView.new, layout: layout
  end

  get '/more-with-haml-layout' do
    phlex MoreDetailsView.new, layout: true, layout_engine: :haml
  end

  get '/stream-with-layout' do
    phlex FooView.new, layout: true, stream: true
  end

  get '/svg' do
    phlex SvgElem.new
  end

  get '/svg-with-layout' do
    phlex SvgElem.new, layout: true
  end

  get '/svg/plain' do
    phlex SvgElem.new, content_type: :text
  end

  get '/xml' do
    phlex FooView.new, content_type: :xml
  end
end

RSpec.describe Phlex::Sinatra do
  include Rack::Test::Methods

  def app
    TestApp
  end

  context 'without the #phlex helper method' do
    it 'the Phlex view is rendered as expected' do
      get '/foo'
      expect(last_response.body).to eql('<p>foo</p>')
    end
  end

  context "using Sinatra's #url helper within a Phlex view" do
    it 'works' do
      get '/link'

      expect(last_response.body).to eql('<a href="/bar">link</a>')
      expect(last_response.media_type).to eql('text/html')
    end

    it 'works when hosted at a sub-path' do
      get '/link', {}, { 'SCRIPT_NAME' => '/foo' }

      expect(last_response.body).to eql('<a href="/foo/bar">link</a>')
      expect(last_response.media_type).to eql('text/html')
    end

    it 'works with full URLs' do
      headers = {
        'HTTP_HOST' => 'foo.example.com',
        'SCRIPT_NAME' => '/foo',
      }
      get '/link', { full: '1' }, headers

      expect(last_response.body).to eql('<a href="http://foo.example.com/foo/bar">link</a>')
      expect(last_response.media_type).to eql('text/html')
    end
  end

  context 'when #phlex is called from within another view' do
    it 'works the same' do
      get '/inline', {}, { 'SCRIPT_NAME' => '/foo' }

      expect(last_response.body).to start_with('<main><a href="/foo/bar">link</a></main>')
    end

    it 'allows passing a layout' do
      get '/inline_with_layout'

      expect(last_response.body).to start_with('<main><div><a href="/bar">link</a></div>')
    end
  end

  context 'when passing content_type' do
    it 'responds correctly' do
      get '/xml'

      expect(last_response.body).to eql('<p>foo</p>')
      expect(last_response.media_type).to eql('application/xml')
    end
  end

  context 'when a layout is passed' do
    it 'uses the specified layout' do
      get '/more-with-layout'

      expect(last_response.body).to start_with('<div><pre>')
    end

    it "uses Sinatra's default layout when `true`" do
      get '/more-with-layout', { layout: 'true' }

      expect(last_response.body).to start_with('<main><pre>')
    end

    it 'raises an error stream=true' do
      expect {
        get('/stream-with-layout')
      }.to raise_error(Phlex::Sinatra::IncompatibleOptionError)
    end

    it 'works with non-ERB templates' do
      get '/more-with-haml-layout'

      expect(last_response.body).to start_with("<article>\n<pre>")
    end
  end

  context 'when passed a Phlex::SVG view' do
    it 'defaults to SVG content type' do
      get '/svg'

      expect(last_response.body).to start_with('<svg><rect')
      expect(last_response.media_type).to eql('image/svg+xml')
    end

    it 'does not default to SVG content type if a layout is specified' do
      get '/svg-with-layout'

      expect(last_response.body).to start_with('<main><svg><rect')
      expect(last_response.media_type).to eql('text/html')
    end

    it 'can also have its content type specified' do
      get '/svg/plain'

      expect(last_response.body).to start_with('<svg><rect')
      expect(last_response.media_type).to eql('text/plain')
    end
  end

  context "when the thing passed to #phlex isn't a Phlex instance" do
    it 'raises an error and displays the input string' do
      expect {
        get '/error', { type: 'string' }
      }.to raise_error(Phlex::Sinatra::TypeError, %r{"<p>foo</p>"})
    end

    it "limits the input when it's a long string" do
      expect {
        get '/error', { type: 'string-long' }
      }.to raise_error(Phlex::Sinatra::TypeError, /"<p>a b c d e f g h i j k l m n …/)
    end

    it 'raises an error and displays the input class' do
      expect {
        get '/error', { type: 'phlex-class' }
      }.to raise_error(Phlex::Sinatra::TypeError, /FooView/)
    end
  end

  context "using Sinatra's other helpers" do
    it 'works' do
      get '/more', { a: 1, b: 2 }

      expect(last_response.body).to eql('<pre>{&quot;a&quot;=&gt;&quot;1&quot;, &quot;b&quot;=&gt;&quot;2&quot;}</pre>')
      expect(last_response.media_type).to eql('text/html')
    end
  end
end
