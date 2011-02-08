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

import javax.xml.parsers.ParserConfigurationException;

import org.xml.sax.SAXException;

import CS2JNet.System.NotImplementedException;
import CS2JNet.System.Xml.XmlDocument;

public class XmlTextReader {
	protected XmlDocument xmlDocument = null;
	
	protected XmlDocument getXmlDocument() throws ParserConfigurationException {
		if (xmlDocument == null) {
			xmlDocument = new XmlDocument();
		}
		return xmlDocument;
	}
	public XmlTextReader() throws NotImplementedException {
		throw new NotImplementedException();
	}
	
	public XmlTextReader(StringReader stringReader) throws NotImplementedException, ParserConfigurationException, SAXException, IOException {
		getXmlDocument().load(stringReader);
	}
	
	public String ToString() throws ParserConfigurationException {
		return getXmlDocument().getOuterXml();
	}
}
