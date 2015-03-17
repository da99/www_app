

require 'cuba'
require 'da99_rack_protect'
require 'multi_json'
require 'www_app'

PATH = File.expand_path(File.dirname(__FILE__) + '../../..')

Rack::Mime::MIME_TYPES.merge!({".map" => "application/json"})

Cuba.use Da99_Rack_Protect do |c|
  c.config :host, :localhost if ENV['IS_DEV']
end

if ENV['IS_DEV']
  # Cuba.use Rack::ShowExceptions
end

PAGES = {
  :root => WWW_App.new {
      title { 'hello' }
      background 'lightgrey'
      font_family 'Ubuntu Mono, monospace'
      color '#2C2C2D'

      style {
        div {
          border '1px dotted #fff'
          margin '10px'
          padding '10px'
          float 'left'
          min_width '80px'
        }

        div.^(:prepend) {
          border '1px dashed #000'
        }

        div.^(:append) {
          border '1px solid #000'
        }
      }

      script :news, :good do
        div.^(:good) {
          span { 'GOOD: ' }
          span { :msg }
        }
      end

      script :news, :bad do
        div.^(:bad) { :msg }
      end

      script do
        div { text('First: '); span { :first } }
      end

      script do
        div { text('Last: '); span { :last } }
      end

      script do
        div {
          text "This is a movie: "
          span { :movie }
        }
      end

      script :prepend do
        div.^(:prepend) {
          text "TOP movie: "
          span { :movie }
        }
      end

      p {
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

    on 'error' do
      something
    end
  end

end # === Cuba.define

run Cuba

