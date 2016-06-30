module Liquid
  module Tags
    class NowInMilliseconds < Liquid::Tag                                             
      def render(context)
        (Time.now.to_f * 1000).to_i
      end
    end
  end
end
