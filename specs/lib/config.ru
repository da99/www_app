

require 'cuba'
require 'da99_rack_protect'

Cuba.use Da99_Rack_Protect.config { |c|
  c.config :host, [:localhost, 'www_applet.com']
}

Cuba.use Rack::ShowExceptions

Cuba.use(Class.new {
  def initialize app
    @app = app
  end

  def call env
    results = @app.call(env)
    if results.first == 404
      [
        Rack::Directory.new(File.expand_path('./specs/lib')),
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

    on(root) {
      res.write <<-EOF
    <html>
      <head>
        <title>WWW_Applet client side</title>
        <style type="text/css">
          body {
            background: #F5F5FF;
          }
        </style>
      </head>
      <body>
      testing
      </body>
    </html>
      EOF
    }

    on(default) {
      res.status = 404
      res.write 'Missing'
    }

  end # === on get

end # === Cuba.define

run Cuba
