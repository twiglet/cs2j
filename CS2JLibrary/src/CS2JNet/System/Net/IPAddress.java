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

package CS2JNet.System.Net;

import java.net.InetAddress;
import java.net.UnknownHostException;

/**
 * @author keving
 *
 */
public class IPAddress {

	private byte[] address;
	private boolean isAny = false;
	
	/**
	 * @return the address
	 */
	public byte[] getAddress() {
		return address;
	}

	/**
	 * @param address the address to set
	 */
	public void setAddress(byte[] address) {
		this.address = address;
	}

	/**
	 * 
	 * @return If true, provides an IP address that indicates that the server must listen for client activity on all network interfaces
	 */
	public boolean isAny() {
		return this.isAny;
	}

	public IPAddress(byte[] inAddress, boolean any) {
		setAddress(inAddress);
		this.isAny = any;
	}
	
	public IPAddress(byte[] inAddress) {
		this(inAddress, false);
	}
	
	public static final IPAddress Any = new IPAddress(null, true);
	
	public String toString()
	{
		String ret = "";
		try {
			ret = InetAddress.getByAddress(address).toString();
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		return ret;
	}

}
