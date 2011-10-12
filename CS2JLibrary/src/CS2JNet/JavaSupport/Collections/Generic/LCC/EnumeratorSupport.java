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
package CS2JNet.JavaSupport.Collections.Generic.LCC;

import java.util.Collection;
import java.util.Iterator;

import CS2JNet.JavaSupport.CS2JRunTimeException;
import CS2JNet.System.Collections.LCC.IEnumerator;

/**
 * A concrete implementation of .Net's Enumerator that wraps an Iterator
 * 
 * @author keving
 *
 * @param <T>
 */
public class EnumeratorSupport<T> implements IEnumerator<T> {

	private Iterator<T> myIterator = null;
	private T myCurrent = null;
	
	public static <S> EnumeratorSupport<S> mk(Iterator<S> inIt) {
		return new EnumeratorSupport<S>(inIt);
	}

	public EnumeratorSupport(Iterator<T> it) {
		myIterator = it;
	}

	public T getCurrent() throws Exception {
		return myCurrent;
	}

	public boolean moveNext() throws Exception {
		boolean hasNext = myIterator.hasNext();
		if (hasNext) {
			myCurrent = myIterator.next();
		}
		return hasNext;
	}

	public void reset() throws Exception {
		throw new CS2JRunTimeException("CS2J: IEnumerator does not yet support Reset() operation");
	}

	public Iterator<T> iterator() {
		return myIterator;
	}
	
}
