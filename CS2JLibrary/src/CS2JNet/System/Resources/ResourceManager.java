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

package CS2JNet.System.Resources;

import java.util.ResourceBundle;
import java.util.MissingResourceException;

import CS2JNet.JavaSupport.util.LocaleSupport;

public class ResourceManager {

	private ResourceBundle bundle = null;

	/**
	 * Initializes the ResourceBundle with the given resource name.  This implementation
	 * ignores the assembly object.  Note that a CurrentLocale object was created to hold
	 * the ThreadLocal Locale.  This value is set by the Integration.SetCulture() method and
	 * it is utilized here.
	 * 
	 * @param resourceName
	 * @param assembly
	 */
	public ResourceManager(String resourceName, Object assembly)
	{
		bundle = ResourceBundle.getBundle(resourceName, LocaleSupport.getCurrentLocale());
	}
	
	// By returning null the caller will use the passed in string
	public String getString(String name)
	{
		try {
			return bundle.getString(name);
		} catch (MissingResourceException e) {
			return null;
		}
	}
}
