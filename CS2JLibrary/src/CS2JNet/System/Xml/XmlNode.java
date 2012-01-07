/*
   Copyright 2007,2008,2009,2010 Rustici Software, LLC
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Author(s):

   Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

package CS2JNet.System.Xml;

import java.io.IOException;
import java.io.StringReader;
import java.util.Iterator;

import org.w3c.dom.*;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import CS2JNet.System.StringSupport;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.*;

public class XmlNode implements Iterable {

	private Node node = null;
	
	// We ignore the text nodes between children because that is 
	// what .Net seems to do (and our appn relies on)
	private class XmlNodeIterator implements Iterator
	{

		Node prev = null;
		Node pos = null;
		
		public XmlNodeIterator() {
			pos = node.getFirstChild();
			while (pos != null && pos instanceof Text)
				pos = pos.getNextSibling();
		}
		
		public boolean hasNext() {
			return pos != null;
		}

		public Object next() {
			Node prev = pos;
			pos = pos.getNextSibling();
			while (pos != null && pos instanceof Text)
				pos = pos.getNextSibling();
			return wrapNode(prev);
		}

		public void remove() {
			node.removeChild(prev);
		}
		
	}
	public XmlNode()
	{
		
	}
	public XmlNode(Node n)
	{
	   node = n;	
	}
	
	// Is there a better way to do this?  We want that if the parent 
	// is a node we get an XmlNode, if it is an element we get an 
	// XmlElement and so on.
	public static XmlNode wrapNode(Node n)
	{

		if (n == null)
			return null;
		if (n instanceof Element)
			return new XmlElement((Element) n);
		if (n instanceof Document)
			return new XmlDocument((Document) n);
		if (n instanceof Attr)
			return new XmlAttribute((Attr) n);
		if (n instanceof Comment)
			return new XmlComment((Comment) n);
		if (n instanceof CDATASection)
			return new XmlCDataSection((CDATASection) n);
		if (n instanceof Text)
			return new XmlText((Text) n);
		return new XmlNode(n);
//		switch (n.getNodeType())
//		{
//			case Node.ELEMENT_NODE:
//				return new XmlElement((Element) n);
//			default:
//				return new XmlNode(n);
//		}
	}
	protected void setNode(Node n)
	{
		node = n;
	}

	public Node getNode()
	{
		return node;
	}
	
	// TODO: (keving) or should we return c? 
	public XmlNode appendChild(XmlNode c)
	{
		return wrapNode(node.appendChild(c.node));
	}

	public XmlNode insertBefore(XmlNode c, XmlNode r)
	{
		return wrapNode(node.insertBefore(c.node, r.node));
	}

	public XmlAttributeCollection getAttributes()
	{
		return new XmlAttributeCollection(node.getAttributes());
	}
	
	public String getName()
	{
		return node.getNodeName();
	}

	public String getNamespaceURI()
	{
		return node.getNamespaceURI();
	}

	public String getLocalName()
	{
		String localName = node.getLocalName();
		if (localName != null)
			return localName;
		
		// No localName,  this might be because this node was "created with a DOM Level 1 method, such as Document.createElement(), this is always null"
		// return part following any ':'
		localName = node.getNodeName();
		int colPos = localName.lastIndexOf(':');
		if (colPos > 0)
			return localName.substring(colPos + 1);
		else
		    return localName;
	}
	
	// Fix System/Xml/XmlNodeType.xml to recognise more types
	public short getNodeType()
	{
		return node.getNodeType();
	}

	public XmlNodeList getChildNodes()
	{
		return new XmlNodeList(node.getChildNodes());
	}

	public XmlNode getFirstChild()
	{
		return wrapNode(node.getFirstChild());
	}

	public String getInnerText()
	{
		// I think the XML standard says that newlines in text are converted from their
		// local encoding to "\n".  Java does that, but .Net does not, so here we put 'em back.
		return node.getTextContent().replace("\n", System.getProperty("line.separator"));
	}
	
	public boolean isEmptyElement()
	{
        if (StringSupport.IsEmptyOrBlank(node.getTextContent()) && getAttributes().size() == 0 && getChildNodes().size() == 0)
        {
            return true;
        }
        else
        {
            return false;
        }
		
	}

	// This is a .Net extension to the DOM.  It returns markup describing
	// this node's children.
	public String getInnerXml()
	{
		StringBuffer sb = new StringBuffer();
		for (XmlNode c : getChildNodes())
		{
			c.getOuterXml(sb);
		}
		return sb.toString();
	}

	public XmlNode getNextSibling()
	{
		return wrapNode(node.getNextSibling());
	}

	// This is a .Net extension to the DOM.  It returns markup containing this node
	// and all its children.
	public String getOuterXml()
	{
		StringBuffer sb = new StringBuffer();
		getOuterXml(sb);
		return sb.toString();
	}

	protected void getOuterXml(StringBuffer sb)
	{
		sb.append("get_OuterXml() not implemented for " + getClass().toString());
	}

	public XmlDocument getOwnerDocument()
	{
		return new XmlDocument(node.getOwnerDocument());
	}

	public XmlNode getParentNode()
	{
		return wrapNode(node.getParentNode());
	}

	// TODO: (keving) or should we return c? 
	public XmlNode removeChild(XmlNode c)
	{
		return wrapNode(node.removeChild(c.node));
	}
		
	public XmlNode selectSingleNode(String xpath) throws XPathExpressionException
	{
			XPathFactory  factory=XPathFactory.newInstance();
			XPath xPath=factory.newXPath();
			Node n = (Node) xPath.evaluate(xpath,
			        getNode(), XPathConstants.NODE);
			return wrapNode(n);
	}

	// This is a .Net extension to the DOM.  It replaces the children with
	// nodes parsed from the string.  
	public void setInnerXml(String value) throws ParserConfigurationException, SAXException, IOException
	{
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		Document dummyDoc = builder.parse(new InputSource(new StringReader("<DUMMY>" + value + "</DUMMY>")));
		Node importableNode = getNode().getOwnerDocument().importNode(dummyDoc.getDocumentElement(), true);
		Node myNode = getNode();
		
		// First we remove all existing children
		Node child = myNode.getFirstChild();
		while (child != null)
		{
			Node tmp = child;
			child = child.getNextSibling();
			myNode.removeChild(tmp);
		}
		
		// Now we insert the new children
		child = importableNode.getFirstChild();
		while (child != null)
		{
			Node tmp = child;
			child = child.getNextSibling();
			myNode.appendChild(tmp);
		}
		
		//myNode.replaceChild(importableNode, myNode.getFirstChild());
	}

	public void setInnerText(String value)
	{
		getNode().setTextContent(value);
	}

	public XmlNodeList selectNodes(String xpath) throws XPathExpressionException
	{

			XPathFactory  factory=XPathFactory.newInstance();
			XPath xPath=factory.newXPath();
			NodeList ns = (NodeList) xPath.evaluate(xpath,
			        getNode(), XPathConstants.NODESET);
			return new XmlNodeList(ns);
	}

	public Iterator iterator() {
		return new XmlNode.XmlNodeIterator();
	}
	
	public void removeAll() {
		
		 // Remove all the attributes of an element
	    NamedNodeMap attrs = node.getAttributes();
	    String[] names = new String[attrs.getLength()];
	    for (int i=0; i<names.length; i++) {
	        names[i] = attrs.item(i).getNodeName();
	    }
	    for (int i=0; i<names.length; i++) {
	        attrs.removeNamedItem(names[i]);
	    }
		
		 NodeList list = node.getChildNodes();
         for (int i=0; i<list.getLength(); i++) {
        	 node.removeChild(list.item(i));
         }

	}

}
