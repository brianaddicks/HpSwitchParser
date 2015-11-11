using System;
using System.Xml;
using System.Web;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Collections.Generic;
namespace HpSwitchParser {
	public class AccessList {
		public string Name { get; set; }
		public int Number { get; set; }
		public List<AclRule> Rules { get; set; }
    }
	public class AclRule {
		public int Number;
		public string Action;
		public string Protocol;
		
		public string Source;
		public string SourcePort;
		
		public string Destination;
		public string DestinationPort;
    }
	
    public class Interface {
		public string Name;
		public string Description;
		
		public string IpAddress;
		public List<string> DhcpRelayList;
		public bool DhcpRelayEnabled;
		public bool PimSmEnabled;
		
		public string PortLinkType;
		public string PortLinkMode;
		public bool IsShutdown;
		
		public string LinkAggMode;
		public int LinkAggGroup;
		
		public bool MadEnabled;
		
		public List<int> PermittedVlans;
		public int Pvid;
		
		public Interface () {
			this.PermittedVlans = new List<int> {1};
			this.Pvid            = 1;
		}
    }
	
    public class Neighbor {
		public string LocalPort;
		public string ChassisId;
		public string RemotePort;
		public string SystemName;
		public string IpAddress;
		public string Capabilities;
    }
	
    public class Vlan {
		public int Id;
		public string Name;
		public string Description;
		public string IpAddress;
		public List<string> DhcpRelayList;
		public bool DhcpRelayEnabled;
		public int AclIn;
		public int AclOut;
    }
}
