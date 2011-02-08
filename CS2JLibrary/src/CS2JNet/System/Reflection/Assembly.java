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

package CS2JNet.System.Reflection;

import java.net.URL;
import java.net.URLClassLoader;

/*
 * An assembly is a dll, equivalent to a jar. For now, we assume the
 * loaded class will be on the classpath. Maybe, by setting the assembly
 * name here we should be able to look off classpath. 
 */
public class Assembly {
	
	private String assemblyName = "";
	
	public Assembly(String aStr)
	{
		// 
		assemblyName = aStr;
	}
	
	public Class getClass(String claName, boolean throwOnError) throws Exception
	{
		Class ret = null;
		
		try
		{
//	        //Get the System Classloader
//	        ClassLoader sysClassLoader = ClassLoader.getSystemClassLoader();
//
//	        //Get the URLs
//	        URL[] urls = ((URLClassLoader)sysClassLoader).getURLs();
//
//	        System.out.println("System ClassPath:");
//	        
//	        for(int i=0; i< urls.length; i++)
//	        {
//	            System.out.println(urls[i].getFile());
//	        }       
//
//	        //Get the thread's Classloader
//	        ClassLoader threadClassLoader = Thread.currentThread().getContextClassLoader();
//
//	        //Get the URLs
//	        URL[] threadUrls = ((URLClassLoader)threadClassLoader).getURLs();
//
//	        System.out.println("\n\nThread's ClassPath:");
//	        
//	        for(int i=0; i< threadUrls.length; i++)
//	        {
//	            System.out.println(threadUrls[i].getFile());
//	        }       

			// In multi-threaded applications this ensures we get the right classloader
////			System.out.println("Looking for class " + claName);
//			Thread myThread = Thread.currentThread();
//			ClassLoader myThreadClassLoader = myThread.getContextClassLoader();
//			ret = myThreadClassLoader.loadClass(claName);
			//Thread myThread = Thread.currentThread();
			//ClassLoader myThreadClassLoader = myThread.getContextClassLoader();
			ret = this.getClass().getClassLoader().loadClass(claName);
		}
		catch (Exception e)
		{
			if (throwOnError)
				throw e;
			else
				ret = null;
		}
		
		return ret;
	}

}
