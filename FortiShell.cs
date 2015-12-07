using System;
using System.Xml;
using System.Web;
using System.Security.Cryptography.X509Certificates;
using System.Net;
using System.Net.Security;
using System.IO;
using System.Collections.Generic;
namespace FortiShell {
	
    public class Address {
		public string Name;
		public string Value;
		public string Interface;
    }
	
    public class Service {
		public string Name;
		public List<string> Value;
    }
	
    public class ServiceGroup {
		public string Name;
		public List<string> Value;
    }
}
