require "open-uri"

module Liquid
  module Tags
    class MarketsByState < Liquid::Tag

      def initialize(tag_name, markup, tokens)
        super
        args = markup.split(" ")
        @publisher_label = args.first.strip
      end

      def render(context)
        publisher = Publisher.find_by_label(@publisher_label)
        result = "<div id='markets_by_state'>"
        result << states_letter_nav(publisher)

        unless publisher.nil?
          first_letter = "A"
          result << "<div id='#{first_letter}_states' style='display: none'>"

          ::Addresses::Codes::US::STATE_CODES.each do |state_code|
            if state_code.chars.first != first_letter
              first_letter = state_code.chars.first
              result << "</div><div id='#{first_letter}_states' style='display: none'>"
            end

            markets_for_state = publisher.markets_with_deals_for_state(state_code)

            unless markets_for_state.empty?
              result << "<div id='#{state_code.downcase}_markets' class='market_block'>"
              result << "<div class='state_name'>#{::Addresses::Codes::US::STATE_NAMES_BY_CODE[state_code]}:</div>"
              result << "<div class='state_markets'>"
              market_links = []

              markets_for_state.each do |market|
                market_links << "<a href='/publishers/#{publisher.label}/#{market.label}/deal-of-the-day'>#{market.name}</a>"
              end

              result << market_links.join("&nbsp;|&nbsp;")
              result << "</div>" # state_markets div
              result << "</div>" # _markets div
            end

          end
          result << "</div>" # final _states div
        end

        result << "</div>" # markets_by_state div
      end

      private

      def states_letter_nav(publisher)
        %Q{
          <div id="states_letter_nav"><a class='state_letter_inactive'>A</a>&nbsp;<a class='state_letter_inactive'>C</a>&nbsp;<a class='state_letter_inactive'>D</a>&nbsp;<a class='state_letter_inactive'>F</a>&nbsp;<a class='state_letter_inactive'>G</a>&nbsp;<a class='state_letter_inactive'>H</a>&nbsp;<a class='state_letter_inactive'>I</a>&nbsp;<a class='state_letter_inactive'>K</a>&nbsp;<a class='state_letter_inactive'>L</a>&nbsp;<a class='state_letter_inactive'>M</a>&nbsp;<a class='state_letter_inactive'>N</a>&nbsp;<a class='state_letter_inactive'>O</a>&nbsp;<a class='state_letter_inactive'>P</a>&nbsp;<a class='state_letter_inactive'>R</a>&nbsp;<a class='state_letter_inactive'>S</a>&nbsp;<a class='state_letter_inactive'>T</a>&nbsp;<a class='state_letter_inactive'>U</a>&nbsp;<a class='state_letter_inactive'>V</a>&nbsp;<a class='state_letter_inactive'>W</a>
          	<a class="market_national_link" href='/publishers/#{publisher.label}/national/deal-of-the-day'>National</a></div>
          
        }
      end

    end
  end
end