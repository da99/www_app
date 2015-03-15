

require 'cuba'
require 'da99_rack_protect'
require 'multi_json'
require 'www_app'

PATH = File.expand_path(File.dirname(__FILE__) + '../../..')

Rack::Mime::MIME_TYPES.merge!({".map" => "application/json"})

Cuba.use Da99_Rack_Protect do |c|
  c.config :host, :localhost if ENV['IS_DEV']
end

Cuba.use Rack::ShowExceptions

PAGES = {
  :root => WWW_App.new {
      title { 'hello' }
      script 'text/hogan' do
        div {
          :author
        }
      end
      div {
        _.^(:happy) {
          border '1px dashed red'
        }
        "Almost done."
      }
    }
}

Cuba.use Rack::Static, :urls=>["/www_app-#{File.read(PATH + '/VERSION').strip}"], :root=>'Public'

Cuba.define do

  on get do
    on root do
      res.write PAGES[:root].to_html
    end
  end

  on post do
    data = (req.env["rack.request.form_hash"]).dup
    data.delete('authenticity_token')

    res['Content-Type'] = 'application/json';

    on(default) {
      res.status = 404
      res.write 'Missing'
    }
  end

  on get do

    on(default) {
      res.status = 404
      res.write 'Missing'
   }

  end # === on get

end # === Cuba.define

run Cuba

