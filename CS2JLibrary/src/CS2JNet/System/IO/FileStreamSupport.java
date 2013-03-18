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

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;

import CS2JNet.JavaSupport.CS2JRunTimeException;

/**
 * 
 * @author kevin.glynn@twiglet.com
 *
 */
public class FileStreamSupport  {


	private FileInputStream inputStream = null;
	private FileOutputStream outputStream = null;
	
	/***
	 * Initializes a new instance of the FileStreamSupport class with the specified path, 
	 * creation mode, and read/write permission
	 * 
	 * This class mimics System.IO.FileStream
	 * 
	 * If mode is read only then set readStream, if write only then set writeStream, 
	 * if readWrite throw an exception :(
	 * @param path
	 * @param mode
	 * @param access
	 * @throws FileNotFoundException 
	 * @throws CS2JRunTimeException 
	 */
	public FileStreamSupport(String path, FileMode mode, FileAccess access) throws FileNotFoundException, CS2JRunTimeException {
		switch (access) {
		case Read:
			setInputStream(new FileInputStream(path));
			break;
		case Write:
			setOutputStream(new FileOutputStream(path, mode == FileMode.Append));
			break;
		case ReadWrite:
		default:
			throw new CS2JRunTimeException("CS2J: Read / Write FileStreams are not yet supported");
		}
	}

	/**
	 * @param inputStream the inputStream to set
	 */
	public void setInputStream(FileInputStream inputStream) {
		this.inputStream = inputStream;
	}

	/**
	 * @return the inputStream
	 */
	public FileInputStream getInputStream() {
		return inputStream;
	}

	/**
	 * @param outputStream the outputStream to set
	 */
	public void setOutputStream(FileOutputStream outputStream) {
		this.outputStream = outputStream;
	}

	/**
	 * @return the outputStream
	 */
	public FileOutputStream getOutputStream() {
		return outputStream;
	}
}
