module Nagios

  module HttpPlugin

    def render_nagios_critical(message)
      render :text => "CRITICAL - #{message}"
    end

    def render_nagios_warning(message)
      render :text => "WARNING - #{message}"
    end

    def render_nagios_ok(message)
      render :text => "OK - #{message}"
    end

  end

end
