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
public enum AddressFamily {

	Unknown, 		//	Unknown address family.
	Unspecified, 	//	Unspecified address family.
	Unix, 			//	Unix local to host address.
	InterNetwork, 	//	Address for IP version 4.
	ImpLink, 		//	ARPANET IMP address.
	Pup, 			//	Address for PUP protocols.
	Chaos, 			//	Address for MIT CHAOS protocols.
	NS, 			//	Address for Xerox NS protocols.
	Ipx, 			//	IPX or SPX address.
	Iso, 			//	Address for ISO protocols.
	Osi, 			//	Address for OSI protocols.
	Ecma, 			//	European Computer Manufacturers Association (ECMA) address.
	DataKit, 		//	Address for Datakit protocols.
	Ccitt, 			//	Addresses for CCITT protocols, such as X.25.
	Sna, 			//	IBM SNA address.
	DecNet, 		//	DECnet address.
	DataLink, 		//	Direct data-link interface address.
	Lat, 			//	LAT address.
	HyperChannel, 	//	NSC Hyperchannel address.
	AppleTalk, 		//	AppleTalk address.
	NetBios, 		//	NetBios address.
	VoiceView, 		//	VoiceView address.
	FireFox, 		//	FireFox address.
	Banyan, 		//	Banyan address.
	Atm, 			//	Native ATM services address.
	InterNetworkV6, //	Address for IP version 6.
	Cluster, 		//	Address for Microsoft cluster products.
	Ieee12844, 		//	IEEE 1284.4 workgroup address.
	Irda, 			//	IrDA address.
	NetworkDesigners, //	Address for Network Designers OSI gateway-enabled protocols.
	Max 			//MAX address.
}
