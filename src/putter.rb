#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'net/http'
require 'uri'
require 'atomURI'
require 'crumbs'

class Putter

  attr_reader :last_error, :response, :crumbs, :headers

  def initialize(uriString, authent)
    @crumbs = Crumbs.new
    @last_error = nil
    @uri = AtomURI.check(uriString)
    if (@uri.class == String)
      @last_error = @uri
    end
    @authent = authent
    @headers = {}
  end
  
  def set_header(name, val)
    @headers[name] = val
  end


  def put(contentType, body, req = nil)
    req = Net::HTTP::Put.new(AtomURI.on_the_wire(@uri)) unless req
    @authent.add_to req
    
    req.set_content_type contentType
    @headers.each { |k, v| req[k]= v }

    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.scheme == 'https'
      http.set_debug_output @crumbs if @crumbs
      http.start do |connection|
        @response = connection.request(req, body)
        
        if @response.kind_of?(Net::HTTPUnauthorized) && @authent
           @authent.add_to req, @response['WWW-Authenticate']
            return put(contentType, body, req)
        end
        
        unless @response.kind_of? Net::HTTPSuccess
          @last_error = @response.message
          return false
        end
        
        return true
      end
    rescue Exception
      @last_error = "Can't connect to #{@uri.host} on port #{@uri.port}: #{$!}"
      return nil
    end
  end
end
