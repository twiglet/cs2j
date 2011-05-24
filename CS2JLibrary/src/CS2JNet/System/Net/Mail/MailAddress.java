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

/**
 * @author keving
 *
 */
public class MailAddress {

	private String address, displayName, host, user;

	private void parseAddress(String add) {
		// TODO: parse address into fields
		address = add;
	}
	
	public MailAddress(String inAddress) {
		parseAddress(inAddress);
	}
	
	public MailAddress(String inAddress, String inDisplayName) {
		parseAddress(inAddress);
		if (inDisplayName != null && inDisplayName.length() > 0)
			inAddress = inDisplayName;
	}
	
	// TODO:
	//public MailAddress(String inAddress, Encoding enc) {
	//	parseAddress(inAddress);
	//	if (inDisplayName != null && inDisplayName.length() > 0)
	//		inAddress = inDisplayName;
	//}
	
	
	/**
	 * @param displayName the displayName to set
	 */
	public void setDisplayName(String displayName) {
		this.displayName = displayName;
	}

	/**
	 * @return the displayName
	 */
	public String getDisplayName() {
		return displayName;
	}

	/**
	 * @param host the host to set
	 */
	public void setHost(String host) {
		this.host = host;
	}

	/**
	 * @return the host
	 */
	public String getHost() {
		return host;
	}

	/**
	 * @param user the user to set
	 */
	public void setUser(String user) {
		this.user = user;
	}

	/**
	 * @return the user
	 */
	public String getUser() {
		return user;
	}

	/**
	 * @param address the address to set
	 */
	public void setAddress(String address) {
		this.address = address;
	}

	/**
	 * @return the address
	 */
	public String getAddress() {
		return address;
	}
	
}
