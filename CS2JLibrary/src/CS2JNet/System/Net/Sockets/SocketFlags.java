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

/**
 * @author keving
 *
 */
public enum SocketFlags {

	None,		//	Use no flags for this call.
	OutOfBand,	//	Process out-of-band data.
	Peek,		//	Peek at the incoming message.
	DontRoute,	//	Send without using routing tables.
	MaxIOVectorLength,	//	Provides a standard value for the number of WSABUF structures that are used to send and receive data.
	Truncated,	//	The message was too large to fit into the specified buffer and was truncated.
	ControlDataTruncated,	//	Indicates that the control data did not fit into an internal 64-KB buffer and was truncated.
	Broadcast,	//	Indicates a broadcast packet.
	Multicast,	//	Indicates a multicast packet.
	Partial		//	Partial send or receive for message.
}
