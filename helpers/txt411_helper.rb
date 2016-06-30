module Txt411Helper
  def row1(options = {}, &block)
    block_to_partial('txt411/row1', options, &block)
  end

  def row2(options = {}, &block)
    block_to_partial('txt411/row2', options, &block)
  end

  def box(options = {}, &block)
    block_to_partial('txt411/box', options, &block)
  end

  def box2(options = {}, &block)
    block_to_partial('txt411/box2', options, &block)
  end

  def txt411_image_path(source)
    image_path("txt411/" + source)
  end

  def navbar_item(active_tag, tag, normal_img, active_img, href)
    if active_tag == tag
      %Q(<img src="/images/txt411/#{active_img}" alt="" name="#{tag}" id="#{tag}"/>).html_safe
    else
      i = %Q(<img src="/images/txt411/#{normal_img}" alt="" name="#{tag}" id="#{tag}"/>)
      %Q(<a href="#{href}" onmouseout="MM_swapImgRestore()" onmouseover="MM_swapImage('#{tag}','','#{txt411_image_path(active_img)}',1)">#{i}</a>).html_safe
    end
  end
end
