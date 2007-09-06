#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'atomURI'
require 'invoker'

class Deleter < Invoker

  def delete( req = nil )
    req = Net::HTTP::Delete.new(AtomURI.on_the_wire(@uri)) unless req

    begin
      http = prepare_http
      
      http.start do |connection|
        @response = connection.request(req)
        
        return delete(req) if need_authentication?(req)
        
        return true if @response.kind_of? Net::HTTPSuccess

        @last_error = @response.message
        return false
      end
    rescue Exception
      @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
      return nil
    end
  end
end
