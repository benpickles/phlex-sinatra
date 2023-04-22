# frozen_string_literal: true

class FooView < Phlex::HTML
  def template
    p { 'foo' }
  end
end

class LinkView < Phlex::HTML
  def initialize(full)
    @full = full
  end

  def template
    a(href: url('/bar', @full)) { 'link' }
  end
end

class TestApp < Sinatra::Application
  set :environment, :test

  get '/foo' do
    FooView.call
  end

  get '/link' do
    phlex LinkView.new(params[:full])
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

  context 'when passing content_type' do
    it 'responds correctly' do
      get '/xml'

      expect(last_response.body).to eql('<p>foo</p>')
      expect(last_response.media_type).to eql('application/xml')
    end
  end
end
