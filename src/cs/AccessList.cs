using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace HpSwitchParser {
	public class AccessList {
		public string Name { get; set; }
		public int Number { get; set; }
		public List<AclRule> Rules { get; set; }
    }
}