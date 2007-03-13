#   Copyright © 2006 Sun Microsystems, Inc. All rights reserved
#   Use is subject to license terms - see file "LICENSE"

require 'rexml/document'
require 'rexml/xpath'
require 'cgi'

require 'atomURI'
require 'namespaces'

# represents an Atom Entry
class Entry

  # @element is the REXML dom
  # @base is the base URI if known

  def initialize(node, uri = nil)
    if node.class == String
      @element = REXML::Document.new(node, { :raw => nil }).root
    else
      @element = node
    end
    if uri
      @base = AtomURI.new(uri)
    else
      @base = nil
    end
  end

  def to_s
    @element.to_s
  end

  def content_src
    content = REXML::XPath.first(@element, './atom:content', $atomNS)
    if content
      content.attributes['src']
    else
      nil
    end
  end

  def get_child(field, namespace = nil)
    if (namespace)
      thisNS = {}
      thisNS['atom'] = $atomNamespace
      prefix = 'NN'
      thisNS[prefix] = namespace
    else
      prefix = 'atom'
      thisNS = $atomNS
    end
    xpath = "./#{prefix}:#{field}"
    return REXML::XPath.first(@element, xpath, thisNS)
  end

  def add_category(term, scheme = nil, label = nil)
    c = REXML::Element.new('atom:category', @element)
    c.add_namespace('atom', $atomNamespace)
    c.add_attribute('term', term)
    c.add_attribute('scheme', scheme) if scheme
    c.add_attribute('label', label) if label
    c
  end

  def has_cat(cat)
    xpath = "./atom:category[@term=\"#{cat.attributes['term']}\""
    if cat.attributes['scheme']
      xpath += "and @scheme=\"#{cat.attributes['scheme']}\""
    end
    xpath += "]"
    REXML::XPath.first(@element, xpath, $atomNS)
  end

  def delete_category(c)
    @element.delete_element c
  end

  def child_type(field)
    n = get_child(field, nil)
    (n) ? n.attributes['type'] : nil
  end

  def child_content(field, namespace = nil)
    n = get_child(field, namespace)
    return nil unless n
    
    # if it's type="xhtml", we'll get the content out of the contained
    #  XHTML <div> rather than this element
    if n.attributes['type'] == 'xhtml'
      n = REXML::XPath.first(n, "./xhtml:div", $xhtmlNS)
    end 
  
    text_from n
  end

  def text_from node
    text = ''
    is_html = node.name =~ /(rights|subtitle|summary|title|content)$/ && node.attributes['type'] == 'html'
    node.find_all do | child |
      if child.kind_of? REXML::Text
        v = child.value
        v = CGI.unescapeHTML(v).gsub(/&apos;/, "'") if is_html
        text << v
      elsif child.kind_of? REXML::Element
        text << text_from(child)
      end
    end
    text
  end

  def link(rel)
    a = REXML::XPath.first(@element, "./atom:link[@rel=\"#{rel}\"]", $atomNS)
    if a
      l = a.attributes['href']
      l = @base.absolutize(l, @element) if @base
    else
      nil
    end
  end
  
  def alt_links
    REXML::XPath.match(@element, "./atom:link", $atomNS).select do |l|
      l.attributes['rel'] == nil || l.attributes['rel'] == 'alt'
    end
  end

  def summarize
    child_content('title')
  end

  # debugging
  def Entry.dump(node, depth=0)
    prefix = '.' * depth
    name = node.getNodeName
    uri = node.getNamespaceURI
    if uri
      puts "#{prefix} #{uri}:#{node.getNodeName}"
    else
      puts "#{prefix} #{node.getNodeName}"
    end
    Nodes.each_node(node.getChildNodes) {|child| dump(child, depth+1)}

  end

end
