require "nokogiri"

class Page

  class << self

    def unindent s
      s.gsub(/^#{s.scan(/^\s*/).min_by{|l|l.length}}/, "")
    end

  end # === class self

  NEW = self.unindent <<-EOHTML
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>[No Title]</title>
        <style type="text/css">
        </style>
      </head>
      <body>
      </body>
    </html>
  EOHTML


  def initialize
    @html = nil
  end

  def title
    @title ||= "[No title]"
  end

  def new_tag type, content
    raw = {:tag=>type, :childs=>nil, :content=>nil}
    if content.is_a?(Array)
      raw[:childs] = content
    else
      raw[:content] = content
    end

    raw
  end

  def elements
    e = [
      new_tag("p", [new_tag("span", "help 1")]),
      new_tag("p", [new_tag("span", "help 2")]),
      new_tag("p", "help 3"),
    ]
  end

  def elements_to_html o
    case
    when o.is_a?(Array)
      o.map { |e| elements_to_html e }.join "\n#{indent_spaces}"
    when o.is_a?(Hash)
      "<#{o[:tag]}>#{elements_to_html o[:content]}</#{o[:tag]}>"
    when o.is_a?(String)
      o
    else
      fail "Unknown type: #{o.inspect}"
    end
  end

  def doc
    @doc ||= Nokogiri::HTML Page::NEW
  end

  def new_element raw
    e = Nokogiri::XML::Node.new(raw[:tag], doc)

    if raw[:content]
      e.content = raw[:content]
    end

    if raw[:childs]
      raw[:childs].each { |raw_child|
        e.add_child new_element(raw_child)
      }
    end

    e
  end

  def to_html
    @html ||= begin
                body = doc.at_css "body"

                elements.each { |raw|
                  body.add_child new_element(raw)
                }

                doc.to_html
              end
  end

end # === class Page

puts Page.new.to_html
