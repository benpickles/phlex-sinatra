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
  def initialize(full)
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

class StreamingView < Phlex::HTML
  def view_template
    html {
      head {
        title { 'Streaming' }
      }
      body {
        p { 1 }
        flush # Internal private Phlex method.
        p { 2 }
      }
    }
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

  get '/link' do
    phlex LinkView.new(params[:full])
  end

  get '/more' do
    phlex MoreDetailsView.new
  end

  get '/stream' do
    phlex StreamingView.new, stream: true
  end

  get '/svg' do
    phlex SvgElem.new
  end

  get '/svg/plain' do
    phlex SvgElem.new, content_type: :text
  end

  get '/xml' do
    phlex FooView.new, content_type: :xml
  end
end

# Trick Capybara into managing Puma for us.
class NeedsServerDriver < Capybara::Driver::Base
  def needs_server?
    true
  end
end

Capybara.register_driver :needs_server do
  NeedsServerDriver.new
end

Capybara.app = TestApp
Capybara.default_driver = :needs_server
Capybara.server = :puma, { Silent: true }

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

  context 'when passing content_type' do
    it 'responds correctly' do
      get '/xml'

      expect(last_response.body).to eql('<p>foo</p>')
      expect(last_response.media_type).to eql('application/xml')
    end
  end

  context 'with a Phlex::SVG view' do
    it 'responds with the correct content type by default' do
      get '/svg'

      expect(last_response.body).to start_with('<svg><rect')
      expect(last_response.media_type).to eql('image/svg+xml')
    end

    it 'can also specify a content type' do
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

  context 'when streaming' do
    def get2(path)
      Net::HTTP.start(
        Capybara.current_session.server.host,
        Capybara.current_session.server.port,
      ) { |http|
        http.get(path)
      }
    end

    it 'outputs the full response' do
      last_response = get2('/stream')

      expect(last_response.body).to eql('<html><head><title>Streaming</title></head><body><p>1</p><p>2</p></body></html>')

      # Indicates that Sinatra's streaming is being used.
      expect(last_response['Content-Length']).to be_nil
    end
  end
end
