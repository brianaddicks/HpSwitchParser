using System;
using System.Xml;
using System.Web;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Collections.Generic;
namespace HpSwitchParser {
	
    public class Vlan {
		public int Id;
		public string Name;
		public string Description;
		public string IpAddress;
		public List<string> DhcpRelayList;
		public bool DhcpRelayEnabled;
    }
}
