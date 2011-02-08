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

import org.w3c.dom.Attr;
import org.w3c.dom.Element;


public class XmlElement extends XmlLinkedNode {

	
	protected XmlElement()
	{
		
	}
	public XmlElement(Element e)
	{
	   setNode(e);	
	}
	
	private Element getElement()
	{
		return (Element)getNode();
	}
		
	protected void getOuterXml(StringBuffer sb)
	{
		String tag = getName();
		
		sb.append("<");
		sb.append(tag);
		for (XmlAttribute a : getAttributes())
		{
			sb.append(" ");
			a.getOuterXml(sb);
		}
		sb.append(">");
		for (XmlNode n : getChildNodes())
		{
			n.getOuterXml(sb);
		}
		sb.append("</" + tag + ">");
		
	}

	public boolean hasAttribute(String att)
	{
		return getElement().hasAttribute(att);
	}

	public String getAttribute(String att)
	{
		return getElement().getAttribute(att);
	}

	public boolean hasAttributes()
	{
		return getElement().hasAttributes();
	}

	public XmlNodeList getElementsByTagName(String name)
	{
		return new XmlNodeList(((Element)getNode()).getElementsByTagName(name));
	}

	public void removeAttribute(String att)
	{
		getElement().removeAttribute(att);
	}

	public void setAttribute(String att, String val)
	{
		getElement().setAttribute(att, val);
	}

	public void setAttributeNS(String uri, String att, String val)
	{
		getElement().setAttributeNS(uri, att, val);
	}
	
	public void setAttributeNode(XmlAttribute att)
	{
		getElement().setAttributeNode((Attr)att.getNode());
	}

	public short getNodeType()
	{
		return getElement().getNodeType();
	}



}
