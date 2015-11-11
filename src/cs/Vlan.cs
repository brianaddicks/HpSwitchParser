using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace HpSwitchParser {
	
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