

require 'cuba'
require 'da99_rack_protect'

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
        env['PATH_INFO'] = '/index.html'
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

  on get do

    # on(root) {
      # res.write 
    # }

    on(default) {
      res.status = 404
      res.write 'Missing'
    }

  end # === on get

end # === Cuba.define

run Cuba
