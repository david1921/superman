module TextSanitizer
      
  module_function

  def sanitize(text)
    return text if text.nil? || text.empty?

    sanitize_html_tags(sanitize_entities(sanitize_non_ascii(text)))
  end

  def sanitize_entities(text)
    return text if text.nil? || text.empty?
    
    # word is fond of these things
    text = text.gsub("&#8211;", '-')    #en dash
    text = text.gsub("&#8212;", '--')   #em dash
    text = text.gsub("&#8216;", "'")    #single left quote
    text = text.gsub("&#8217;", "'")    #single right quote
    text = text.gsub("&#8220;", '"')    #double left quote
    text = text.gsub("&#8221;", '"')    #double right quote
    text = text.gsub("&#8226;", '*')    #bullet
    text = text.gsub("&#8230;", '...')  #elipsis
    text = text.gsub("&#8364;", 'E')    #euros
    text = text.gsub("&#8482;", '(TM)') #trademark

    # unsupported
    text = text.gsub("&#8218;", "")  #low 9 single quote
    text = text.gsub("&#8222;", '')  #double low nine quote
    text = text.gsub("&#8224;", '')  #dagger
    text = text.gsub("&#8225;", '')  #double-dagger
    text = text.gsub("&#8240;", '')  #per thousand sign
    text = text.gsub(/&#\d*;/, '')   #anything else

    text
  end

  def sanitize_non_ascii(text)
    return text if text.nil? || text.empty?

    text = text.gsub("–", '-')    #en dash
    text = text.gsub("—", '--')   #em dash
    text = text.gsub("‘", "'")    #single left quote
    text = text.gsub("’", "'")    #single right quote
    text = text.gsub("“", '"')    #double left quote
    text = text.gsub("”", '"')    #double right quote
    text = text.gsub("•", '*')    #bullet
    text = text.gsub("…", '...')  #elipsis
    text = text.gsub("€", 'E')    #euros
    text = text.gsub("™", '(TM)') #trademark

    # unsupported
    text = text.gsub("‚", "")  #low 9 single quote
    text = text.gsub("„", '')  #double low nine quote
    text = text.gsub("†", '')  #dagger
    text = text.gsub("‡", '')  #double-dagger
    text = text.gsub("‰", '')  #per thousand sign

    # anything else
    text = text.gsub("&nbsp;", ' ') #non-breaking space trips up AR validations
    
    tmp = ''
    text.scan(/./mu).each { |x| tmp << x unless x.unpack("U")[0] > 127 }
    text = tmp

    text
  end

  def sanitize_html_tags(text)
    return text if text.nil? || text.empty?

    Sanitize.clean(text, Sanitize::Config::BASIC)
  end
end