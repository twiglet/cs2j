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

import CS2JNet.System.Net.Sockets.AddressFamily;

/**
 * @author keving
 *
 */
public class IPEndPoint extends EndPoint {

	public static final int MaxPort = 0x0000FFFF;
	public static final int MinPort = 0x00000000;

	private IPAddress ipAddress;
	private AddressFamily addressFamily; 
	private int port = 0;
	/**
	 * @return the address
	 */
	public IPAddress getIPAddress() {
		return ipAddress;
	}
	/**
	 * @param address the address to set
	 */
	public void setIPAddress(IPAddress address) {
		this.ipAddress = address;
	}

	@Override
	public AddressFamily getAddressFamily() {
		return addressFamily;
	}
	
	/**
	 * @return the port
	 */
	public int getPort() {
		return port;
	}
	/**
	 * @param port the port to set
	 */
	public void setPort(int port) {
		this.port = port;
	}
	
	public IPEndPoint(byte[] address, int port) {
		setIPAddress(new IPAddress(address));
		setPort(port);
	}
	
	public IPEndPoint(IPAddress address, int port) {
		setIPAddress(address);	
		setPort(port);
	}

	/**
	 * 
	 * @return If true, provides an IP address that indicates that the server must listen for client activity on all network interfaces
	 */
	public boolean isAny() {
		return ipAddress != null && ipAddress.isAny();
	}

	
}
