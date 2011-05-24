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

package CS2JNet.System.Net.Mail;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

/**
 * @author keving
 *
 */
public class MailAddressCollection implements Collection<MailAddress> {

	List<MailAddress> addresses = new ArrayList<MailAddress>();
	
	@Override
	public boolean add(MailAddress arg0) {
		return addresses.add(arg0);
	}

	public boolean add(String arg0) {
		return addresses.add(new MailAddress(arg0));
	}

	@Override
	public boolean addAll(Collection<? extends MailAddress> arg0) {
		return addresses.addAll(arg0);
	}

	@Override
	public void clear() {
		addresses.clear();
		
	}

	@Override
	public boolean contains(Object arg0) {
		return addresses.contains(arg0);
	}

	@Override
	public boolean containsAll(Collection<?> arg0) {
		return addresses.containsAll(arg0);
	}

	@Override
	public boolean isEmpty() {
		return addresses.isEmpty();
	}

	@Override
	public Iterator<MailAddress> iterator() {
		return addresses.iterator();
	}

	@Override
	public boolean remove(Object arg0) {
		return addresses.remove(arg0);
	}

	@Override
	public boolean removeAll(Collection<?> arg0) {
		return addresses.removeAll(arg0);
	}

	@Override
	public boolean retainAll(Collection<?> arg0) {
		return addresses.retainAll(arg0);
	}

	@Override
	public int size() {
		return addresses.size();
	}

	@Override
	public Object[] toArray() {
		return addresses.toArray();
	}

	@Override
	public <T> T[] toArray(T[] arg0) {
		return (T[]) addresses.toArray();
	}

}
