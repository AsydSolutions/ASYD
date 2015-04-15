class MyFlavoredMarkdown < Redcarpet::Render::HTML
  def postprocess(text)
    add_relative_link(text)
  end

  def add_relative_link(text)
    text.gsub! /"(.*.md)"/ do
      "/help/#{$1}"
    end
    text
  end
end

def flavored_markdown(path)
  text = File.read("static/"+path)
  renderer = MyFlavoredMarkdown.new()
  # These options might be helpful but are not required
  options = {
    safe_links_only: false,
    no_intra_emphasis: true,
    autolink: true
  }
  Redcarpet::Markdown.new(renderer, options).render(text)
end
