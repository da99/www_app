

require 'cuba'
require 'da99_rack_protect'
require 'multi_json'

Cuba.use Da99_Rack_Protect.config { |c|
  c.config :host, [:localhost, 'www_app.com']
}

Cuba.use Rack::ShowExceptions

Cuba.use(Class.new {
  def initialize app
    @app = app
  end

  def call env
    results = @app.call(env)
    if results.first == 404
      if env['PATH_INFO'] == '/'
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

Cuba.define do

  on post do
    on "repeat/vals" do
      data = (req.env["rack.request.form_hash"]).dup
      data.delete('authenticity_token')

      res['Content-Type'] = 'application/json';
      res.write MultiJson.dump({
        'data' => data
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
