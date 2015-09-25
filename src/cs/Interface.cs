using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

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
}