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

package CS2JNet.System.Net.Sockets;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

import CS2JNet.System.InvalidOperationException;
import CS2JNet.System.NotImplementedException;

import CS2JNet.System.Net.EndPoint;
import CS2JNet.System.Net.IPEndPoint;

/**
 * @author keving
 *
 */
public class NetSocket {

	private EndPoint endPoint = null;
	
	private AddressFamily addressFamily = null;
	private SocketType socketType = null;
	private ProtocolType protocolType = null;
	
	// local booleans so that we can quickly see that correct protocol has been followed
	private boolean bindCalled = false;
	private boolean listenCalled = false;
	
    public NetSocket(AddressFamily inAddressFamily,
    		SocketType inSocketType,
    		ProtocolType inProtocolType) {
    	addressFamily = inAddressFamily;
    	socketType = inSocketType;
    	protocolType = inProtocolType;
    }
    
    public NetSocket() {
    }

    
    private ServerSocket serverSocket = null;
    
    private Socket clientSocket = null;
    
    private OutputStream outStream = null;
    private InputStream inStream = null;
    /***
     * 
     * @param ep
     */
	public void bind(EndPoint ep) {
		bindCalled = true;
		endPoint = ep;
	}
	
	/***
	 * 
	 * @param backlog
	 * @throws SocketException
	 * @throws IOException 
	 */
	public void listen(int backlog) throws SocketException, IOException {
		if (!bindCalled) {
			throw new SocketException();
		}
		listenCalled = true;
		if (endPoint != null && endPoint instanceof IPEndPoint) {
			IPEndPoint ipEndPoint = (IPEndPoint) endPoint;
			if (ipEndPoint.isAny()) {
				serverSocket = new ServerSocket(ipEndPoint.getPort(), backlog);
			}
			else {
				serverSocket = new ServerSocket(ipEndPoint.getPort(), backlog, InetAddress.getByAddress(ipEndPoint.getIPAddress().getAddress()));
			}
		}
	}

	/***
	 * 
	 * @return
	 * @throws InvalidOperationException 
	 * @throws IOException 
	 */
	public NetSocket accept() throws InvalidOperationException, IOException {
		if (!bindCalled || !listenCalled || serverSocket == null) 
			throw new InvalidOperationException();
		
		Socket client = serverSocket.accept();
		NetSocket ret = new NetSocket();
		ret.clientSocket = client;
		
		return ret;
	}

	public EndPoint getRemoteEndPoint() {
		EndPoint ret = null;
		if (clientSocket != null) {
			ret = new IPEndPoint(clientSocket.getInetAddress().getAddress(), clientSocket.getPort());
		}
		return ret;
	}

	/***
	 * 
	 * @param data
	 * @param length
	 * @param none
	 * @return number pf bytes sent
	 * @throws IOException 
	 * @throws NotImplementedException 
	 */
	public int receive(byte[] data, int size, SocketFlags socketFlags) throws IOException, NotImplementedException {
		if (socketFlags != SocketFlags.None) {
			throw new NotImplementedException("CS2J: socket receive does not yet support flags other than SocketFlags.None");
		}
		if (inStream == null) {
			inStream = clientSocket.getInputStream();
		}	
		int ret = inStream.read(data, 0, size);
		return (ret == -1 ? 0 : ret);
	}
	
	/***
	 * 
	 * @param data
	 * @param socketFlags
	 * @return
	 * @throws IOException
	 * @throws NotImplementedException
	 */
	public int receive(byte[] data, SocketFlags socketFlags) throws IOException, NotImplementedException {
		return receive(data, data.length, socketFlags);
	}
	
	/***
	 * 
	 * @param data
	 * @return
	 * @throws IOException
	 * @throws NotImplementedException
	 */
	public int receive(byte[] data) throws IOException, NotImplementedException {
		return receive(data, data.length, SocketFlags.None);
	}
	
	/***
	 * 
	 * @param data
	 * @param length
	 * @param none
	 * @return number pf bytes sent
	 * @throws IOException 
	 * @throws NotImplementedException 
	 */
	public int send(byte[] data, int size, SocketFlags socketFlags) throws IOException, NotImplementedException {
		if (socketFlags != SocketFlags.None) {
			throw new NotImplementedException("CS2J: socket send does not yet support flags other than SocketFlags.None");
		}
		int ret = size;
		if (outStream == null) {
			outStream = clientSocket.getOutputStream();
		}
		outStream.write(data, 0, size);
		return ret;
	}
	
	/***
	 * 
	 * @param data
	 * @param socketFlags
	 * @return
	 * @throws IOException
	 * @throws NotImplementedException
	 */
	public int send(byte[] data, SocketFlags socketFlags) throws IOException, NotImplementedException {
		return send(data, data.length, socketFlags);
	}
	
	/***
	 * 
	 * @param data
	 * @return
	 * @throws IOException
	 * @throws NotImplementedException
	 */
	public int send(byte[] data) throws IOException, NotImplementedException {
		return send(data, data.length, SocketFlags.None);
	}

	/***
	 * Closes any open sockets
	 * @throws IOException
	 */
	public void close() throws IOException {
		if (inStream != null)
			inStream.close();
		if (outStream != null)
			outStream.close();
		if (clientSocket != null)
			clientSocket.close();
		if (serverSocket != null)
			serverSocket.close();
	}

}
