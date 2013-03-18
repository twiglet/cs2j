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

import javax.xml.parsers.*;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.xml.sax.InputSource;
import org.xml.sax.SAXException;  
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.w3c.dom.DOMImplementation;
import org.w3c.dom.Document;

public class XmlDocument extends XmlNode {

	private static Logger logger = Logger.getLogger(XmlDocument.class.getName());

	public XmlDocument() throws ParserConfigurationException
	{
		DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
		DocumentBuilder builder = factory.newDocumentBuilder();
		DOMImplementation impl = builder.getDOMImplementation();

		Document doc = impl.createDocument(null,null,null);
		setNode(doc);
	}
	public XmlDocument(Document d)
	{
	   setNode(d);	
	}
	
	public void load(String p) throws ParserConfigurationException, SAXException, IOException
	{
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			//.Net's xml load is namespace-aware by default.
			factory.setNamespaceAware(true);
			DocumentBuilder builder = factory.newDocumentBuilder();
			File inF = new File(p);
			setNode(builder.parse( inF ));
	}
	
	public void load(StringReader r) throws ParserConfigurationException, SAXException, IOException
	{
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setNamespaceAware(true);
			DocumentBuilder builder = factory.newDocumentBuilder();
			setNode(builder.parse(new InputSource(r)));
	}
	
	public void load(InputStream r, boolean nameSpaceAware) throws ParserConfigurationException, SAXException, IOException
	{
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			factory.setNamespaceAware(nameSpaceAware);
			DocumentBuilder builder = factory.newDocumentBuilder();
			setNode(builder.parse(r));
	}
	
	// overload for translation from .net, which treats load() as namespace aware
	public void load(InputStream r) throws ParserConfigurationException, SAXException, IOException
	{
		load(r,true);
	}
	public void loadXml(String content) throws ParserConfigurationException, SAXException, IOException
	{
			DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
			// By observations .Net's LoadXml method is not namespace aware, but its Load method is
			factory.setNamespaceAware(false);
            DocumentBuilder builder = factory.newDocumentBuilder(); 
            // Can't read the string directly -- the parse(string) method expects the 
            // string to be a URI -- not the actual xml 
            Reader reader = new StringReader(content); 
            setNode(builder.parse( new InputSource(reader)));	}
	
	public XmlNode appendChild(XmlDeclaration decl)
	{
		if (decl.standalone != null)
		{
			((Document)getNode()).setXmlStandalone("yes".equals(decl.standalone.toLowerCase()));
		}
		
		((Document)getNode()).setXmlVersion(decl.version);
		
		// We can't set the encoding, it's read only.  Need to get it right when you write out the 
		// document
		
		return this;
	}

	public XmlComment createComment(String data)
	{
		return new XmlComment(((Document)getNode()).createComment(data));
	}

	public XmlCDataSection createCDataSection(String data)
	{
		return new XmlCDataSection(((Document)getNode()).createCDATASection(data));
	}

	public XmlAttribute createAttribute(String name)
	{
		return new XmlAttribute(((Document)getNode()).createAttribute(name));
	}

	public XmlAttribute createAttribute(String qname, String namespaceuri)
	{
		return new XmlAttribute(((Document)getNode()).createAttributeNS(namespaceuri, qname));
	}

	public XmlAttribute createAttribute(String prefix, String name, String namespaceURI)
	{
		return new XmlAttribute(((Document)getNode()).createAttributeNS(namespaceURI, prefix + ":" + name));
	}

	public XmlElement createElement(String name)
	{
		return new XmlElement(((Document)getNode()).createElement(name));
	}

	public XmlElement createElement(String name, String prefix)
	{
		XmlElement el = new XmlElement(((Document)getNode()).createElement(name));
		el.setAttribute("xmlns", prefix);
		return el;
	}

	public XmlElement createElement(String prefix, String name, String namespaceURI)
	{
		return new XmlElement(((Document)getNode()).createElementNS(namespaceURI, prefix + ":" + name));
	}

	public XmlText createText(String value)
	{
		return new XmlText(((Document)getNode()).createTextNode(value));
	}

	public XmlElement getDocumentElement()
	{
		return new XmlElement(((Document)getNode()).getDocumentElement());
	}
	
	public XmlNodeList getElementsByTagName(String name)
	{
		return new XmlNodeList(((Document)getNode()).getElementsByTagName(name));
	}
	
	protected void getOuterXml(StringBuffer sb)
	{
		for (XmlNode n : getChildNodes())
		{
			n.getOuterXml(sb);
		}
	}

	public void save(String fileName)
	{
		try
		{
	       // Use a Transformer for output
	       TransformerFactory tFactory = TransformerFactory.newInstance();
	       Transformer transformer = tFactory.newTransformer();

	       // Get (and preserve) Document's DOCTYPE attribute
	       /// TODO: keving: String systemValue = (new File(((Document) getNode()).getDoctype().getSystemId())).getName(); 
	       // transformer.setOutputProperty(OutputKeys.DOCTYPE_SYSTEM, systemValue);

	       DOMSource source = new DOMSource((Document)getNode());
	       StreamResult result = new StreamResult(fileName);
	       transformer.transform(source, result);
		}
		catch (Exception e)
		{			
			logger.log(Level.INFO, "ERROR: Exception while saving XML document " + e.getMessage());
		}

	}
	
}
