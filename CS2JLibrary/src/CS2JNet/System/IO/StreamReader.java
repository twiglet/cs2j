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

package CS2JNet.System.IO;

import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import CS2JNet.System.Text.EncodingSupport;

public class StreamReader  {

	// Mimic the behaviour of .Net StreamReader
	// If we find a BOM at the start of the file then use this to decide encoding
	// otherwise we use the encoding passed in, otherwise we use the default 
	// encoding.
	
	// UTF-8 					EF BB BF
	// UTF-16 Big Endian 		FE FF
	// UTF-16 Little Endian 	FF FE
	// UTF-32 Big Endian 		00 00 FE FF
	// UTF-32 Little Endian 	FF FE 00 00
	
	// I can't think of a clever algorithm to spot the BOMs so it is all 
	// hard coded below
	private static String getEncoding(InputStream is) throws IOException
	{
	
		String encoding = null;

		is.mark(5);
		switch (is.read()) {
		case 0xFE:
			if (is.read() == 0xFF)
				encoding = "UTF-16BE";
			break;

		case 0x00:
			if (is.read() == 0x00 && is.read() == 0xFE && is.read() == 0xFF)
				encoding = "UTF-32BE";
			break;

		case 0xEF:
			if (is.read() == 0xBB && is.read() == 0xBF)
				encoding = "UTF-8";
			break;

		case 0xFF:
			if (is.read() == 0xFE)
				if (is.read() == 0x00 && is.read() == 0x00)
					encoding = "UTF-32LE";
				else
					encoding = "UTF-16LE";
			break;

		default:
			break;

		}
		is.reset();
		return encoding;
	}
	
	
	
	public static InputStreamReader make(InputStream is) throws IOException
	{	   
		InputStreamReader retISR = null;
		String enc = getEncoding(is);
		if (enc != null)
			retISR = new InputStreamReader(is, enc);
		else
			// StreamReaders default to UTF-8 if not specified explicitly or via BOMs
			retISR = new InputStreamReader(is, "UTF-8");
		return retISR;
	}

	public static InputStreamReader make(InputStream is, EncodingSupport cs) throws IOException
	{	       
		String enc = getEncoding(is);
		if (enc != null)
			return new InputStreamReader(is, enc);
		else
			return new InputStreamReader(is, cs.getString());
	}

}
