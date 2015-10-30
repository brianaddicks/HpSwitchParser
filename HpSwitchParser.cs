using System;
using System.Xml;
using System.Web;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Collections.Generic;
namespace HpSwitchParser {
	
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
		/*
		public SecurityRule () {
			this.SourceAddress = new List<string> {"any"};
			this.SourceUser = new List<string> {"any"};
			this.HipProfile = new List<string> {"any"};
			this.DestinationAddress = new List<string> {"any"};
			this.Application = new List<string> {"application-default"};
			this.UrlCategory = new List<string> {"any"};
			this.Allow = true;
			this.LogAtSessionEnd = true;
      		this.RuleType = "universal";
		}
		*/
    
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
    }
}
