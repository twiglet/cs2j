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

import java.util.AbstractList;
import org.w3c.dom.*;

public class XmlAttributeCollection extends AbstractList<XmlAttribute> {

	NamedNodeMap atts;
	
	public XmlAttributeCollection(NamedNodeMap as)
	{
		atts = as;
	}
	
	@Override
	public XmlAttribute get(int idx) {
		return (atts == null ? null : new XmlAttribute((Attr)atts.item(idx)));
	}
	
	public XmlAttribute get(String name) {
		return new XmlAttribute((Attr)atts.getNamedItem(name));
	}

	
	@Override
	public int size() {
		return (atts == null ? 0 : atts.getLength());
	}

}
