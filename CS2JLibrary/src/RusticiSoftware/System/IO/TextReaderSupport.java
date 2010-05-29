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

package RusticiSoftware.System.IO;

import java.io.IOException;
import java.io.Reader;

import RusticiSoftware.System.WrappedException;

public class TextReaderSupport {

	// Implementation of TextReader.ReadToEnd()
	public static String readToEnd(Reader r)
	{
		StringBuilder sb = new StringBuilder();
		
		try {
			int c = r.read();
			
			while (c != -1)
			{
				sb.append((char)c);
				c = r.read();
			}
		} catch (IOException e) {
			throw new WrappedException("readToEnd", e);
		}
		
		return sb.toString();
	}
}
