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
package CS2JNet.JavaSupport.Collections.Generic;

import java.util.Iterator;
import java.util.NoSuchElementException;

import CS2JNet.System.Collections.LCC.IEnumerator;

/**
 * Makes an Iterator from a class implementing IEnumeratorSupport
 * 
 * @author keving
 *
 * @param <T>
 */
public class IteratorSupport<T> implements Iterator<T>{

	private IEnumerator<T> myEnum = null;

	private boolean hasNext = false;
	private T next = null;
	
	public IteratorSupport(IEnumerator<T> inEnum) {
		myEnum = inEnum;
	}

	public static <S> IteratorSupport<S> mk(IEnumerator<S> inEnum) {
		IteratorSupport<S> ret = new IteratorSupport<S>(inEnum);
		ret.advanceNext();
		return ret;
	}
	
	private void advanceNext() {
		// advance next and hasNext
		try {
			hasNext = myEnum.moveNext();
			if (hasNext)
				next = myEnum.getCurrent();
		} catch (Exception e) {
			hasNext = false;
		}
	}

	/***
	 * hasNext() can be called multiple times and should keep returning the same answer
	 * until next() has been called.
	 */
	public boolean hasNext() {
		return hasNext; 
	}

	public T next() {
		if (!hasNext) {
			throw new NoSuchElementException();
		}
		
		// remember next element to be returned
		T ret = next;
		
		// advance for future calls
		this.advanceNext();
		
		// and return the element we were holding on to.
		return ret;
	}

	public void remove() {
		throw new UnsupportedOperationException("CS2J: IteratorSupport.remove()");
		
	}
	
}
