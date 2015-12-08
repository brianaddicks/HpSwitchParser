using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Xml;
using System.Web;

namespace FortiShell {
	
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
}