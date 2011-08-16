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
public enum ProtocolType {

	IP, 					//	Internet Protocol.
	IPv6HopByHopOptions, 	//	IPv6 Hop by Hop Options header.
	Icmp, 					//	Internet Control Message Protocol.
	Igmp, 					//	Internet Group Management Protocol.
	Ggp, 					//	Gateway To Gateway Protocol.
	IPv4, 					//	Internet Protocol version 4.
	Tcp, 					//	Transmission Control Protocol.
	Pup, 					//	PARC Universal Packet Protocol.
	Udp, 					//	User Datagram Protocol.
	Idp, 					//	Internet Datagram Protocol.
	IPv6, 					//	Internet Protocol version 6 (IPv6).
	IPv6RoutingHeader, 		//	IPv6 Routing header.
	IPv6FragmentHeader, 	//	IPv6 Fragment header.
	IPSecEncapsulatingSecurityPayload, 	//	IPv6 Encapsulating Security Payload header.
	IPSecAuthenticationHeader,			//	IPv6 Authentication header. For details, see RFC 2292 section 2.2.1, available at http://www.ietf.org.
	IcmpV6, 				//	Internet Control Message Protocol for IPv6.
	IPv6NoNextHeader, 		//	IPv6 No next header.
	IPv6DestinationOptions, //	IPv6 Destination Options header.
	ND, 					//	Net Disk Protocol (unofficial).
	Raw, 					//	Raw IP packet protocol.
	Unspecified, 			//	Unspecified protocol.
	Ipx, 					//	Internet Packet Exchange Protocol.
	Spx, 					//	Sequenced Packet Exchange protocol.
	SpxII, 					//	Sequenced Packet Exchange version 2 protocol.
	Unknown					//	Unknown protocol.
}
