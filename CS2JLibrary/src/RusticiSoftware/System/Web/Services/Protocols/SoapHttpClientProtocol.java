/*
   Copyright 2007-2010 Rustici Software, LLC

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

   Kevin Glynn (kevin.glynn@scorm.com)
*/

package RusticiSoftware.System.Web.Services.Protocols;

import RusticiSoftware.System.NotImplementedException;
import RusticiSoftware.System.Net.CookieContainer;

public class SoapHttpClientProtocol {
	
	String url;
	CookieContainer cc;
	
	public void setUrl(String inUrl)
	{
		this.url = inUrl;
	}

	public String getUrl()
	{
		return this.url;
	}
	
	public void setCookieContainer(CookieContainer inCc)
	{
		this.cc = inCc;
	}

	public CookieContainer getCookieContainer()
	{
		return this.cc;
	}
	
	public Object[] invoke(String methodName, Object[] parameters) throws NotImplementedException
	{
		throw new NotImplementedException("SoapHttpClientProtocol.invoke(String, Object[])");
	}

}
