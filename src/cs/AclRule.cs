using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace HpSwitchParser {
	public class AclRule {
		public int Number;
		public string Action;
		public string Protocol;
		
		public string Source;
		public string SourcePort;
		
		public string Destination;
		public string DestinationPort;
    }
}