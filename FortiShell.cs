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
	
    public class Policy {
        public int Number;
        public string SourceInterface;
        public string DestinationInterface;
        public string SourceAddress;
        public string DestinationAddress;
        public string Action;
        public string Schedule;
        public string Service;
        public bool Inbound;
        public bool Outbound;
        public string VpnTunnel;
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
