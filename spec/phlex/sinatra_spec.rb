# frozen_string_literal: true

class FooView < Phlex::HTML
  def template
    plain 'foo'
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
end

RSpec.describe Phlex::Sinatra do
  include Rack::Test::Methods

  def app
    TestApp
  end

  it 'works as normal when not using the #phlex helper method' do
    get '/foo'

    expect(last_response.body).to eql('foo')
  end

  context 'using the #phlex helper method' do
    it 'works' do
      get '/link'
      expect(last_response.body).to eql('<a href="/bar">link</a>')
    end

    it 'works when hosted at a sub-path' do
      get '/link', {}, { 'SCRIPT_NAME' => '/foo' }
      expect(last_response.body).to eql('<a href="/foo/bar">link</a>')
    end

    it 'works with full URLs' do
      headers = {
        'HTTP_HOST' => 'foo.example.com',
        'SCRIPT_NAME' => '/foo',
      }
      get '/link', { full: '1' }, headers
      expect(last_response.body).to eql('<a href="http://foo.example.com/foo/bar">link</a>')
    end
  end
end
