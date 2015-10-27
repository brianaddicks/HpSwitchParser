using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace HpSwitchParser {
	
    public class Neighbor {
		public string LocalPort;
		public string ChassisId;
		public string RemotePort;
		public string SystemName;
		public string IpAddress;
    }
}