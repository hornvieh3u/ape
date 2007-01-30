#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/xpath'
require 'atomURI'

class Collection 

  @@appNS = { 'app' => 'http://purl.org/atom/app#' }
  @@atomNS = { 'atom' => 'http://www.w3.org/2005/Atom' }

  attr_reader :title, :accept, :href

  def initialize(input, doc_uri = nil)
    @input = input
    @accept = []
    @title = REXML::XPath.first(input, './atom:title', @@atomNS)

    # sigh, RNC validation *should* take care of this
    unless @title
      raise(SyntaxError, "Collection is missing required 'atom:title'")
    end
    @title = @title.texts.join

    if doc_uri
      uris = AtomURI.new(doc_uri)
      @href = uris.absolutize(input.attributes['href'], input)
    else
      @href = input.attributes['href']
    end

    # now we have to go looking for the accept
    @accept = REXML::XPath.match(input, './app:accept', @@appNS)
    @accept = @accept.collect { |a| a.texts.join }

    if @accept.empty?
      @accept = [ "entry" ]
    end
  end

  def to_s
    input.to_s
  end

  def to_str
    to_s
  end

end
