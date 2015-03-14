

require 'cuba'
require 'da99_rack_protect'
require 'multi_json'
require 'www_app'

Rack::Mime::MIME_TYPES.merge!({".map" => "application/json"})

Cuba.use Da99_Rack_Protect do |c|
  c.config :host, :localhost if ENV['IS_DEV']
end

Cuba.use Rack::ShowExceptions

Cuba.use(Class.new {
  def initialize app
    @app = app
  end

  def call env
    results = @app.call(env)
    if results.first == 404
      if env['PATH_INFO'] == '/old'
        return [
          200,
          {"Content-Type" => "text/html"},
          [File.read("./specs/client-side/index.html").gsub("{token}", env['rack.session']['csrf'])]
        ]
      end

      [
        Rack::Directory.new(File.expand_path('./specs/lib')),
        Rack::Directory.new(File.expand_path('./specs/client-side')),
        Rack::Directory.new(File.expand_path('./lib/public'))
      ].detect { |r|
        status, headers, body = r.call(env)
        return [status, headers, body] if status !=  404
        false
      }
    end

    results
  end
})


PAGES = {
  :root => WWW_App.new {
      title { 'hello' }
      div {
        _.^(:happy) {
          border '1px dashed red'
        }
        on(:click) {
          add_class :happy
        }
        "Almost done."
      }
    }
}

Cuba.use Rack::Static, :urls=>["/www_app-#{File.read('VERSION').strip}"], :root=>'Public'

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

    on "repeat/error_msg" do
      res.write MultiJson.dump({
        'data' => data,
        'clean_html' => {
          'error_msg' => "<span>#{data['error_msg'] || 'Unknown error.'}</span>"
        }
      })
    end

    on "repeat/success_msg" do
      res.write MultiJson.dump({
        'data' => data,
        'clean_html' => {
          'success_msg' => "<span>#{ data['success_msg'] || 'Unknown success'}</span>"
        }
      })
    end

    on "repeat/vals" do
      res.write MultiJson.dump({
        'data' => data.select { |k,v| k['val'] },
        'clean_html' => {
          'success_msg' => 'Success in repeating vals.'
        }
      })
    end

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
