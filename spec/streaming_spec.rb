require 'capybara/rspec'

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

class StreamingApp < Sinatra::Application
  set :environment, :test

  get '/stream' do
    phlex StreamingView.new, stream: true
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

Capybara.app = StreamingApp
Capybara.default_driver = :needs_server
Capybara.server = :puma, { Silent: true }

RSpec.describe Phlex::Sinatra do
  attr_reader :last_response

  def get(path)
    Net::HTTP.start(
      Capybara.current_session.server.host,
      Capybara.current_session.server.port,
    ) { |http|
      @last_response = http.get(path)
    }
  end

  context 'when streaming' do
    it 'outputs the full response' do
      get('/stream')

      expect(last_response.body).to eql('<html><head><title>Streaming</title></head><body><p>1</p><p>2</p></body></html>')

      # Indicates that Sinatra's streaming is being used.
      expect(last_response['Content-Length']).to be_nil
    end
  end
end
