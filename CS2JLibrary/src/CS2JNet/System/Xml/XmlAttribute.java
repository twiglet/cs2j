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

public class XmlAttribute extends XmlNode {

	
	protected XmlAttribute()
	{
		
	}
	public XmlAttribute(Attr a)
	{
	   setNode(a);	
	}
	
	private Attr getAttribute()
	{
		return (Attr)getNode();
	}
	public String getValue()
	{
	   return getAttribute().getValue();	
	}

	public void setValue(String str)
	{
	   getAttribute().setValue(str);	
	}

	protected void getOuterXml(StringBuffer sb)
	{
		String value = getAttribute().getValue();
        sb.append(getAttribute().getName());
        sb.append("=\"");
        char c;

        for (int i = 0; i < value.length(); i++) {
            c = value.charAt(i);
            switch(c) {
                case '<' :
                    sb.append("&lt;");
                    break;
                case '>' :
                	sb.append("&gt;");
                    break;
                case '\'' :
                	sb.append("&apos;");
                    break;
                case '\"' :
                	sb.append("&quot;");
                    break;
                case '&' :
                	sb.append("&amp;");
                    break;
                case '\r' :
                	sb.append("&#xD;");
                    break;
                case '\t' :
                	sb.append("&#x9;");
                    break;
                case '\n' :
                	sb.append("&#xA;");
                    break;
                default :
                	sb.append(c);
                    break;
            }
        }
        sb.append("\"");
	}

}
