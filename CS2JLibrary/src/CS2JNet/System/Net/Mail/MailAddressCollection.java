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

import javax.mail.internet.AddressException;

/**
 * @author keving
 *
 */
public class MailAddressCollection implements Collection<MailAddress> {

	List<MailAddress> addresses = new ArrayList<MailAddress>();

	public boolean add(MailAddress arg0) {
		return addresses.add(arg0);
	}

	public boolean add(String arg0) throws AddressException {
		return addresses.add(new MailAddress(arg0));
	}

	public boolean addAll(Collection<? extends MailAddress> arg0) {
		return addresses.addAll(arg0);
	}

	public void clear() {
		addresses.clear();
		
	}

	public boolean contains(Object arg0) {
		return addresses.contains(arg0);
	}

	public boolean containsAll(Collection<?> arg0) {
		return addresses.containsAll(arg0);
	}

	public boolean isEmpty() {
		return addresses.isEmpty();
	}

	public Iterator<MailAddress> iterator() {
		return addresses.iterator();
	}

	public boolean remove(Object arg0) {
		return addresses.remove(arg0);
	}

	public boolean removeAll(Collection<?> arg0) {
		return addresses.removeAll(arg0);
	}

	public boolean retainAll(Collection<?> arg0) {
		return addresses.retainAll(arg0);
	}

	public int size() {
		return addresses.size();
	}

	public Object[] toArray() {
		return addresses.toArray();
	}

	public <T> T[] toArray(T[] arg0) {
		return (T[]) addresses.toArray();
	}

}
