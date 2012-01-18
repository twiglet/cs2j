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
package CS2JNet.JavaSupport.Collections.Generic.LCC;

import java.util.Collection;
import java.util.Iterator;

import org.apache.commons.lang.NullArgumentException;

import CS2JNet.System.ArgumentException;
import CS2JNet.System.Collections.LCC.ICollection;
import CS2JNet.System.Collections.LCC.IEnumerator;

/**
 * A concrete implementation of .Net's ICollection that wraps a Collection
 * 
 * @author keving
 *
 * @param <T>
 */
public class CollectionSupport<T> implements ICollection<T> {

	private Collection<T> myCollection = null;
	
	public CollectionSupport(Collection<T> inColl) {
		myCollection = inColl;
	}

	public static <S> CollectionSupport<S> mk(Collection<S> inColl) {
		return new CollectionSupport<S>(inColl);
	}

	
	public Iterator<T> iterator() {
		return myCollection.iterator();
	}

	public boolean add(T arg0) {
		return myCollection.add(arg0);
	}

	public boolean addAll(Collection<? extends T> arg0) {
		return myCollection.addAll(arg0);
	}


	public void clear() {
		myCollection.clear();
	}


	public boolean contains(Object arg0) {
		return myCollection.contains(arg0);
	}

	
	public boolean containsAll(Collection<?> arg0) {
		return myCollection.containsAll(arg0);
	}


	public boolean isEmpty() {
		return myCollection.isEmpty();
	}


	public boolean remove(Object arg0) {
		return myCollection.remove(arg0);
	}


	public boolean removeAll(Collection<?> arg0) {
		return myCollection.removeAll(arg0);
	}


	public boolean retainAll(Collection<?> arg0) {
		return myCollection.retainAll(arg0);
	}


	public int size() {
		return myCollection.size();
	}


	public Object[] toArray() {
		return myCollection.toArray();
	}


	public <S> S[] toArray(S[] arg0) {
		return myCollection.toArray(arg0);
	}


	public boolean Contains(T x) throws Exception {
		return myCollection.contains(x);
	}


	public void Add(T x) throws Exception {
		myCollection.add(x);
		
	}


	public boolean Remove(T x) throws Exception {
		return myCollection.remove(x);
	}


	public void Clear() throws Exception {
		myCollection.clear();
		
	}


	public IEnumerator<T> getEnumerator() throws Exception {
		return new EnumeratorSupport<T>(myCollection.iterator());
	}


	public void copyTo(T[] arr, int i) throws Exception {
		if (arr == null) {
			throw new NullArgumentException("arr");
		}
		if (i < 0 || i + myCollection.size() > arr.length) {
			throw new ArgumentException("i");
		}
		int idx = 0;
		for (T e : this) {
			arr[i+idx] = e;
		}
		
	}
	
}
