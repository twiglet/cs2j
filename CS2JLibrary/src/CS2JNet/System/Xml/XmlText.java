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

import org.w3c.dom.Text;

import CS2JNet.System.*;

public class XmlText extends XmlNode {

	
	protected XmlText()
	{
		
	}
	public XmlText(Text t)
	{
	   setNode(t);	
	}
	
	private Text getText()
	{
		return (Text)getNode();
	}
	

	protected void getOuterXml(StringBuffer sb)
	{
		// I think the XML standard says that newlines in text are converted from their
		// local encoding to "\n".  Java does that, but .Net does not, so here we put 'em back.
		Text txt = getText();
		String nodeValue = txt.getNodeValue();
		if(nodeValue != null){
			nodeValue = nodeValue.replace("\n", System.getProperty("line.separator"));
			sb.append(StringSupport.encodeHTML(nodeValue));
		}
	}

}
