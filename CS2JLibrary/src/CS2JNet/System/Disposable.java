/*
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

package CS2JNet.System;

import java.io.Closeable;

/**
 * @author keving
 *
 */
public class Disposable implements IDisposable {

	private Closeable closerVal = null;
	private IDisposable dispVal = null;
	
	public static Disposable mkDisposable(Closeable obj) {
		Disposable ret = new Disposable();
		ret.closerVal = obj;
		return ret;
	}
	public static Disposable mkDisposable(IDisposable obj) {
		Disposable ret = new Disposable();
		ret.dispVal = obj;
		return ret;
	}
	/* (non-Javadoc)
	 * @see CS2JNet.System.IDisposable#Dispose()
	 */
	public void Dispose() throws Exception {
		if (dispVal != null)
			dispVal.Dispose();
		else if (closerVal != null)
			closerVal.close();
	}

}
