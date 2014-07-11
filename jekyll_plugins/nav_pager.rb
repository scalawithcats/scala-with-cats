module Jekyll
  class NavPagerTag < Liquid::Tag
    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]
      toc  = site.config['toc'].flat_map { |item| flattened_toc(item) }

      curr_index = toc.find_index { |item| item == page['url'] }
      prev_index = curr_index && (curr_index > 0) && curr_index - 1
      next_index = curr_index && (curr_index < toc.length - 1) && curr_index + 1

      prev_path  = prev_index && toc[prev_index]
      prev_page  = prev_index && site.pages.find { |page| page.url == prev_path }

      next_path  = next_index && toc[next_index]
      next_page  = next_index && site.pages.find { |page| page.url == next_path }

      ans = '<ul class="nav-pager">'

      if prev_page
        ans += '<li><a class="btn btn-primary" href="' + prev_page.url + '">&laquo; Prev</a></li>'
      end

      if next_page
        ans += '<li><a class="btn btn-primary" href="' + next_page.url + '">Next &raquo;</a></li>'
      end

      ans += '</ul>'

      ans
    end

    def flattened_toc(item)
      if item.is_a? String
        [ item ]
      else
        [ item['head'] ] + (item['body'] || []).flat_map { |item| flattened_toc(item) }
      end
    end
  end
end

Liquid::Template.register_tag('nav_pager', Jekyll::NavPagerTag)
