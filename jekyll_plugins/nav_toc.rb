module Jekyll
  class NavTocTag < Liquid::Tag
    def initialize(name, params, tokens)
      temp = params.strip
      @chapter = if temp.length == 0 then nil else temp end
      super
    end

    def render(context)
      site = context.registers[:site]
      curr = context.registers[:page]

      if @chapter
        toc = site.config['toc'].select { |group| group['head'] == @chapter }
      else
        toc = site.config['toc']
      end

      ans = '<ul class="nav-toc">'
      toc.each { |item| ans += render_group(site, item, curr) }
      ans += '</ul>'

      ans
    end

    def render_group(site, group, curr)
      head = group['head']
      body = group['body']

      head_page  = head && find_page(site, head)
      body_pages = body && body.map { |path| find_page(site, path) }.select { |page| page }
      all_pages  = ( [ head_page ] + body_pages ).select { |page| page }

      ans = ''

      if head && body
        if head_page
          ans += '<li' + render_active([ head_page ], curr, 'nav-toc-group') + '>'
          ans += render_link(head_page, 'nav-toc-heading')
        else
          ans += '<li class="nav-toc-group">'
          ans += '<span class="nav-toc-heading">' + head + '</span>'
        end

        ans += '<ul' + render_active(all_pages, curr, 'nav-toc-menu') + '>'
        body_pages.each do |page|
          ans += '<li' + render_active([ page ], curr) + '>' + render_link(page, nil) + '</li>'
        end
        ans += '</ul>'

        ans += '</li>'
      end

      ans
    end

    def find_page(site, path)
      path && site.pages.find { |page| page.url == path }
    end

    def render_link(page, css_class = nil)
      ans = ''
      if page
        ans += '<a' + (if css_class then ' class="' + css_class + '"' else '' end) + ' href="' + page.url + '">'
        ans += (page.data['title'] || page.url)
        ans += '</a>'
      else
        ans += '<span>-</span>'
      end
      ans
    end

    def render_active(pages, curr, css_class = nil)
      if pages.find { |page| curr['url'] == page.url }
        if css_class
          ' class="active ' + css_class + '"'
        else
          ' class="active"'
        end
      else
        if css_class
          ' class="' + css_class + '"'
        else
          ''
        end
      end
    end
  end
end

Liquid::Template.register_tag('nav_toc', Jekyll::NavTocTag)