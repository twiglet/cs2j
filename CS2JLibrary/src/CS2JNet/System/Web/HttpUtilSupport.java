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

package CS2JNet.System.Web;

import java.io.UnsupportedEncodingException;
import org.apache.commons.lang.*;

public class HttpUtilSupport {
 
	public static String HtmlEncode(String s)   
    {
    	if (s == null)
    		return "";
        return StringEscapeUtils.escapeHtml(s);
    }

	public static String UrlEncode(String s) throws UnsupportedEncodingException  
    {
    	if (s == null)
    		return "";
        return java.net.URLEncoder.encode(s, "UTF-8");
    }

    public static String UrlDecode(String s) throws UnsupportedEncodingException 
    {
    	if (s == null)
    		return "";
    	return java.net.URLDecoder.decode(s, "UTF-8");
    }


}
