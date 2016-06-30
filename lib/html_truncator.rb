# By Henrik Nyh <http://henrik.nyh.se> 2008-01-30.
# Free to modify and redistribute with credit.   
# Changed locally to base length on length of emitted html
require 'hpricot'

module HtmlTruncator
      
  module_function

  # Like the Rails _truncate_ helper but doesn't break HTML tags or entities.
  def truncate_html(text, max_length = 30, ellipsis = "...")
    return if text.nil?
    
    text = TextSanitizer.sanitize_entities(text)

    doc = Hpricot(text.to_s)
    ellipsis_length = Hpricot(ellipsis).to_s.length
    content_length = doc.to_s.length
    actual_length = max_length - ellipsis_length

    result = content_length > max_length ? doc.truncate(actual_length).to_s + ellipsis : text.to_s
    if result == "..."
      result = last_ditch_effort_to_return_something(doc, actual_length, ellipsis)
    end
    result
  end
  
  def last_ditch_effort_to_return_something(doc, max_length, ellipsis) 
    actual_length = max_length - "<p></p>".length
    first_paragraph = (doc/p).first
    return ellipsis unless first_paragraph
    new_paragraph_content =  first_paragraph.inner_text[0,actual_length]
    "<p>#{new_paragraph_content}#{ellipsis}</p>"
  end

end

module HpricotTruncator
  module NodeWithChildren
    def truncate(max_length)
      return self if to_s.length <= max_length
      truncated_node = self.dup
      truncated_node.children = []
      each_child do |node|   
        remaining_length = max_length - truncated_node.to_s.length
        break if remaining_length < node.to_s.length
        truncated_node.children << node.truncate(remaining_length)
      end
      truncated_node
    end
  end

  module TextNode
    def truncate(max_length)    
      # We're using String#scan because Hpricot doesn't distinguish entities. 
      Hpricot::Text.new(content.scan(/&#?[^\W_]+;|./).first(max_length).join)
    end
  end

  module IgnoredTag
    def truncate(max_length)
      self
    end
  end
end

Hpricot::Doc.send(:include,       HpricotTruncator::NodeWithChildren)
Hpricot::Elem.send(:include,      HpricotTruncator::NodeWithChildren)
Hpricot::Text.send(:include,      HpricotTruncator::TextNode)
Hpricot::BogusETag.send(:include, HpricotTruncator::IgnoredTag)
Hpricot::Comment.send(:include,   HpricotTruncator::IgnoredTag)
